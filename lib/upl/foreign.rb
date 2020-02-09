module Upl
  # Register a foreign predicate in prolog
  #
  #  see https://www.swi-prolog.org/pldoc/man?section=modes
  # for meanings of det, semidet, nondet
  module Foreign
    def self.predicates
      @predicates ||= Hash.new
    end

    # name is the predicate name as called prolog
    # mod is the prolog module name
    # arity will be figured out from the blk unless you specify it
    # blk will be called with Term and Tree instances, depending on
    # ground-ness of the term on the prolog end of the call
    def self.register_semidet name, arity = nil, mod: nil, &blk
      arity ||= blk.arity
      arg_types = arity.times.map{Fiddle::TYPE_VOIDP}
      ruby_pred = Fiddle::Closure::BlockCaller.new Fiddle::TYPE_INT, arg_types do |*args|
        # convert args to Upl::Tree or Upl::Variable instances
        ruby_args = args.map do |term_t|
          case term_t.term_type
          when Extern::PL_VARIABLE
            # TODO how to make sure this variable does not outlive the swipl frame?
            Upl::Variable.new term_t
          else
            Upl::Tree.of_term term_t
          end
        end

        # now do the call and convert to swipl
        case (rv = blk.call *ruby_args)
        when true;            Upl::Extern::TRUE
        when false, NilClass; Upl::Extern::FALSE

        # Upl::Extern::(TRUE, FALSE)
        when 0, 1;            rv
        else                  Upl::Extern::TRUE
        end

      # yes, really catch all exceptions because this is the language boundary
      rescue Exception => ex
        # pass the actual exception object through prolog
        # ultimately gets handled by Runtime.query and friends.
        term = Upl::Term.functor :ruby_error, ex
        Extern::PL_raise_exception term.to_term_t
      end

      mod_ptr = Fiddle::Pointer[mod&.to_s || 0]

      fn = Fiddle::Function.new ruby_pred, arg_types, Fiddle::TYPE_INT

      # int PL_register_foreign_in_module(char *mod, char *name, int arity, foreign_t (*f)(), int flags, ...)
      # flags == 0 for semidet, ie only one 'output' value and no need for retry
      # https://www.swi-prolog.org/pldoc/doc_for?object=c(%27PL_register_foreign_in_module%27)
      rv = Upl::Extern.PL_register_foreign_in_module \
        mod_ptr,
        name.to_s,
        arity,
        fn,
        (flags=0)

      rv == 1 or raise "can't register ruby predicate #{name}/#{arity}"

      # NOTE you have to keep ruby_pred and fn around somewhere, otherwise they
      # get garbage collected, and then the callback segfaults.
      predicates[[name,arity].join('/').to_sym] = ruby_pred, fn
    end
  end
end
