module Upl
  # Convert a term into a tree of ruby objects. This is necessary because
  # queries give back their results as terms which are invalidated as soon as
  # the next set of results is calculated. So we need to turn those terms into a
  # ruby representation and keep them around.
  class Tree
    # term is either a Term instance, or a Fiddle::Pointer to a term_t
    def initialize( term )
      init term
    end

    def init term
      case term
      when Term
        @atom = term.atom
        @args = term.args.map do |arg|
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

    def self.term_to_ruby term
      case term.term_type
      when Extern::PL_VARIABLE
        Variable.copy term

      when Extern::PL_ATOM
        atom = Atom.of_term term
        if atom.to_s =~ /^ruby-(\d+)/
          ObjectSpace._id2ref $1.to_i
        else
          atom
        end

      when Extern::PL_INTEGER
        Extern.PL_get_integer term, (int_ptr = Fiddle::Pointer[0].ref)
        int_ptr.ptr.to_i

      when Extern::PL_STRING
        rv = Extern.PL_get_string term, (str_ptr = Fiddle::Pointer[0].ref), (len_ptr = Fiddle::Pointer[0].ref)
        value_ptr = Fiddle::Pointer.new str_ptr.ptr, len_ptr.ptr.to_i
        value_ptr.to_s

      when Extern::PL_NIL
        # TODO maybe this should be [] - see what happens when term_vars has no vars
        # although nil.to_a == []
        nil

      when Extern::PL_TERM
        Tree.new term

      when Extern::PL_LIST_PAIR
        list_to_ary term

      end
    end

    def self.list_to_ary lst
      rv = []

      while Extern::PL_get_nil(lst) != 1 # not end of list
        res = Extern::PL_get_list \
          lst,
          (head = Extern.PL_new_term_ref),
          (rst = Extern.PL_new_term_ref)

        break unless res == 1

        rv << (term_to_ruby head)
        lst = rst
      end

      rv
    end

    def arity; args.size end

    def pretty_print(pp)
      unless atom == :','
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

    protected

    def populate_args count
      (1..arity).each do |i|
        rv = Extern::PL_get_arg i, term_t, (subterm = Extern.PL_new_term_ref)
        if rv == 1
          yield subterm
        else
          puts "#{rv}: can't convert #{i} arg of #{atom}"
          yield subterm
        end
      end
    end
  end
end
