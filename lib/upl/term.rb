module Upl
  # This thing's job is interacting with term_t, whereas Tree's
  # job is being a ruby copy of a term-tree.
  class Term
    def initialize term_or_string
      case term_or_string
      when String
        # sadly, this doesn't keep variable names
        rv = Extern.PL_put_term_from_chars \
          (@term_t = Extern.PL_new_term_ref),
          Extern::Convert::REP_UTF8,
          term_or_string.bytesize,
          Fiddle::Pointer[term_or_string]

        case rv
        when 1; true # all ok
        when 0
          raise "failure parsing term #{term_or_string}, #{Tree.of_term(@term_t).inspect}"
        else
          raise "unknown api return value #{rv}"
        end

      when Fiddle::Pointer
        # assume this is a pointer to a term. Unsafe, but there's no choice really
        @term_t = term_or_string

      else
        raise "can't handle #{term_or_string}"
      end
    end

    attr_reader :term_t
    alias to_term_t term_t

    def self.of_atom atom
      term_t = Extern.PL_new_term_ref
      rv = Extern.PL_put_atom term_t, atom.to_atom
      rv == 1 or raise "can't set term to atom #{atom}"
      term_t
    end

    # returns a term
    #
    # args are things that can be converted to term_t pointers using to_term_t method
    # TODO misnamed. functor means pred_name/n and this is actually
    # :pred_name, arg1, arg2...
    def self.predicate name, *args
      # TODO maybe use a frame or something because this allocates quite a few sub-terms
      rv = Extern.PL_cons_functor_v \
        (term_t = Extern.PL_new_term_ref),
        Extern.PL_new_functor(name.to_sym.to_atom, args.size),
        TermVector[*args].terms
      rv == 1 or raise "can't populate functor #{name}"

      new term_t
    end

    def populate
      rv = Extern::PL_get_name_arity \
        term_t,
        (atom_ptr = Fiddle::Pointer[0].ref),
        (int_ptr = Fiddle::Pointer[0].ref)

      # This happens when the term_t is not a PL_TERM (ie a compound)
      rv == 1 or raise "can't populate term"

      @arity = int_ptr.ptr.to_i
      @atom = Atom.new atom_ptr.ptr

      self
    end

    def == rhs
      @atom == rhs.atom && @arity == rhs.arity && args == rhs.args
    end

    def <=> rhs
      [@atom, @arity] <=> [rhs.atom, rhs.arity]
    end

    def atom
      @atom or begin
        populate
        @atom
      end
    end

    def arity
      @arity or begin
        populate
        @arity
      end
    end

    def to_functor
      Extern::PL_new_functor atom.atom_t, arity
    end

    def to_predicate
      Extern::PL_pred to_functor, Fiddle::NULL
    end

    def tree; @tree || (Tree.of_term term_t) end
    alias to_ruby tree

    def each
      return enum_for :args unless block_given?

      (1..arity).each do |idx|
        rv = Extern::PL_get_arg idx, term_t, (subterm = Extern.PL_new_term_ref)
        rv == 1 or raise "#{rv}: can't convert #{i} arg of #{atom}"
        yield subterm
      end
    end

    include Enumerable

    def first; self[0] end
    def last; self[arity-1] end

    def deconstruct
      map{|t| Term.new t}
    end

    def [](idx)
      # remember args for terms are 1-based
      rv = Extern::PL_get_arg idx+1, term_t, (arg = Extern.PL_new_term_ref)
      rv == 1 or raise "can't access term at #{idx}"
      Term.new arg
    end

    # set term_t[idx] = val_term_t
    # idx is zero-based, unlike the prolog calls
    def []=( idx, val_term_t)
      raise IndexError, "max index is #{arity-1}" if idx >= arity
      rv = Extern.PL_unify_arg idx+1, term_t, val_term_t
      rv == 1 or raise "can't set index #{idx}"
    end

    def pretty_print(pp)
      # to_ruby.pretty_print pp
      pp.text atom.to_s
      pp.text ?/
      pp.text arity.to_s
    end
  end
end
