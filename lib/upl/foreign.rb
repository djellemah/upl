module Upl
  # Register a foreign predicate in prolog
  # Upl::Extern.PL_register_foreign_in_module(char *mod, char *name, int arity, foreign_t (*f)(), int flags, ...)

  # create the foreign predicate as a class in ruby
  #
  # closure = Class.new(Fiddle::Closure) {
  #   def call
  #     10
  #   end
  # }.new(Fiddle::TYPE_INT, [])
  #
  # func = Fiddle::Function.new(closure, [], Fiddle::TYPE_INT)

  # create the foreign predicate as a block in ruby
  #
  # new(ctype, args, abi = Fiddle::Function::DEFAULT, &block)
  # cb = Closure::BlockCaller.new(TYPE_INT, [TYPE_INT]) do |one|
  #   one
  # end
  #
  # func = Function.new(cb, [TYPE_INT], TYPE_INT)

  module Foreign
    def self.predicates
      @predicates ||= Hash.new
    end

    def self.register_semidet name, arity = nil, module: nil, &blk
      arity ||= blk.arity
      arg_types = arity.times.map{Fiddle::TYPE_VOIDP}
      ruby_pred = Fiddle::Closure::BlockCaller.new Fiddle::TYPE_INT, arg_types do |*args|
        case (rv = blk.call *args)
        when true;            Upl::Extern::TRUE
        when false, NilClass; Upl::Extern::FALSE
        when 0, 1;            rv
        else                  Upl::Extern::TRUE
        end
      rescue
        # TODO raise an exception here, otherwise errors get lost in an empty result set.
        Upl::Extern::FALSE
      end

      module_name = Fiddle::Pointer[module_name&.to_s || 0]

      fn = Fiddle::Function.new ruby_pred, arg_types, Fiddle::TYPE_INT
      rv = Upl::Extern.PL_register_foreign_in_module module_name, name.to_s, arity, fn, 0
      rv == 1 or raise "can't register ruby predicate #{name}/#{arity}"

      # NOTE you have to keep ruby_pred and fn around somewhere, otherwise they
      # get garbage collected, and then the callback segfaults.
      predicates[[name,arity].join('/').to_sym] = ruby_pred, fn
    end
  end
end
