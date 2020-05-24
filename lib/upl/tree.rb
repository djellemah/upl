module Upl
  # So Prolog terms are a rose tree. Who woulda thunkit?
  #
  # Convert a term into a tree of ruby objects. This is necessary because
  # queries give back their results as terms which are invalidated as soon as
  # the next set of results is calculated. So we need to turn those terms into a
  # ruby representation and keep them around.
  # TODO rename to Ast
  class Tree
    # term is either a Term instance, or a Fiddle::Pointer to a term_t
    def initialize( term )
      init term
    end

    def init term
      case term
      when Term
        @atom = term.atom
        @args = term.map do |arg|
          self.class.term_to_ruby arg
        end
      when Fiddle::Pointer
        init Term.new term
      end
    end

    attr_reader :atom, :args

    def self.of_term term_t
      term_to_ruby term_t
    end

    def to_ruby; self end

    def self.term_to_ruby term_t
      case term_t.term_type
      when Extern::PL_VARIABLE
        Variable.copy term_t

      when Extern::PL_ATOM
        Atom.of_term(term_t).to_ruby

      # I think integers > 63 bits can be fetched with PL_get_mpz
      # Other than PL_INTEGER, most of these seem to be unused?
      when Extern::PL_INTEGER, Extern::PL_LONG, Extern::PL_INT, Extern::PL_INT64, Extern::PL_SHORT
        rv = Extern.PL_get_int64 term_t, (int_ptr = Fiddle::Pointer[0].ref)
        rv == 1 or raise "Can't convert to int64. Maybe too large."
        int_ptr.ptr.to_i

      when Extern::PL_FLOAT
        rv = Extern.PL_get_float term_t, (double_ptr = Fiddle::Pointer[0].ref)
        rv == 1 or raise "Can't convert to double. Maybe too large."
        bytes = double_ptr[0,8]
        bytes.unpack('D').first

      when Extern::PL_RATIONAL
        raise NotImplemented, 'convert to rational'

      when Extern::PL_STRING
        # TODO could possibly get away with BUF_DISCARDABLE here?

        flag_mod = Upl::Extern::Convert
        rv = Extern.PL_get_nchars \
          term_t,
          (len_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP, Extern::ruby_free_fn)),
          (str_ptr = Fiddle::Pointer.malloc(Fiddle::SIZEOF_VOIDP, Extern::ruby_free_fn)),
          flag_mod::CVT_STRING | flag_mod::BUF_MALLOC | flag_mod::REP_UTF8

        # note that length here is number of octets, not number of utf8 chars
        string = String.new (str_ptr.ptr.to_s len_ptr.ptr.to_i), encoding: Encoding::UTF_8
        # eventually free the malloc'd memory for the string
        str_ptr.ptr.free = Extern::swipl_free_fn
        string

      when Extern::PL_NIL
        # TODO maybe this should be [] - see what happens when term_vars has no vars
        # although nil.to_a == []
        nil

      when Extern::PL_TERM
        Tree.new term_t

      when Extern::PL_LIST_PAIR
        Inter.each_of_list(term_t).map{|term_t| Term.new(term_t).to_ruby}

      when Extern::PL_DICT
        Dict.of_term term_t

      else
        :"#{term_t.type_string} NotImplemented"

      end
    end

    def arity; args.size end

    # for 2.7 case ... in pattern matching
    # for case term; in functor,arg1,arg; arg1
    def deconstruct
      [atom, *args]
    end

    def inspect
      pp = PP.new
      pretty_print pp
      pp.output
    end

    def pretty_print(pp)
      unless atom.to_sym == :','
        pp.text atom.to_s
        if arity > 0
          pp.text ?/
          pp.text arity.to_s
        end
      end

      if arity > 0
        pp.group 1, ?(, ?) do
          args.each_with_index do |ruby_term,i|
            ruby_term.pretty_print pp
            pp.text ?, if i < arity - 1
          end
        end
      end
    end
  end
end
