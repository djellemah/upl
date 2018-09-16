module Upl
  # So Prolog terms are a rose tree. Who woulda thunkit?

  # OK, so I guess this thing's job is interacting with term_t, whereas Tree's
  # job is being a ruby copy of a term-tree.
  class Term
    def initialize term_or_string
      case term_or_string
      when String
        raise "can't do strings yet"
        # PL_chars_to_term term_or_string
      when Fiddle::Pointer
        # assume this is a pointer to a term. Unsafe, but there's no choice really
        @term_t = term_or_string
      else
        raise "can't handle #{term_or_string}"
      end
    end

    attr_reader :term_t

    def to_term_t; term_t end

    # Make a copy of all the term information. Useful for passing in to queries, apparently.
    def self.copy term_t
      copy_term_t = Extern.PL_copy_term_ref term_t
      new copy_term_t
    end

    def self.of_atom atom
      term_t = Extern.PL_new_term_ref
      rv = Extern.PL_put_atom term_t, atom.to_atom
      rv == 1 or raise "can't set term to atom #{atom}"
      term_t
    end

    # args are things that can be converted to term_t pointers using to_term_t method
    def self.functor name, *args
      # TODO maybe use a frame or something because this allocates quite a few sub-terms
      functor_t = Extern.PL_new_functor name.to_sym.to_atom, args.size

      arg_terms = Extern.PL_new_term_refs args.size
      args.each_with_index do |arg,i|
        Extern::PL_unify (arg_terms+i), arg.to_term_t
      end

      term_t = Extern.PL_new_term_ref
      rv = Extern.PL_cons_functor_v term_t, functor_t, arg_terms
      rv == 1 or raise "can't populate functor #{name}"

      new term_t
    end

    def populate
      int_ptr = Runtime::Ptr[0].ref
      atom_ptr = Runtime::Ptr[0].ref
      rv = Extern::PL_get_name_arity term_t, atom_ptr, int_ptr
      # This happens when the term_t is not a PL_TERM (ie a compound)
      raise "can't populate term" unless rv == 1

      @arity = int_ptr.ptr.to_i
      @atom = Atom.new atom_ptr

      self
    end

    def == rhs
      @atom == rhs.atom && @arity == rhs.arity && args == rhs.args
    end

    def <=> rhs
      [@atom, @arity] <=> [rhs.atom, rhs.arity]
    end

    # attr_reader :atom, :arity

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
      Extern::PL_new_functor atom.atom_ptr, arity
    end

    def to_predicate
      Extern::PL_pred to_functor, Extern::NULL
    end

    def tree; @tree || (Tree.of_term term_t) end
    def to_ruby; tree end

    # Assume that term_t still has a value. Which means we have to copy all
    # values before the underlying term_t is changed.
    # TODO leaning hard towards each with Enumerable
    def args
      return enum_for :args unless block_given?

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

    # set term_t[idx] = val_term_t
    # idx is zero-based, unlike the prolog calls
    def []=( idx, val_term_t)
      raise IndexError, "max index is #{arity-1}" if idx >= arity
      rv = Extern.PL_unify_arg(idx+1, term_t, val_term_t)
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
