module Upl
  # Just an idea, not used yet.
  class Functor
    def initialize( atom, args_or_arity )
      @atom = atom

      case args_or_arity
      when Array
        @args = args_or_arity
        @arity = args.size
      when Integer
        @arity = args_or_arity
      else
        "dunno bout #{args_or_arity.inspect}"
      end
    end

    attr_reader :atom
    def args; @args || [] end
    def arity; @arity || args.size end

    # create a functor_t pointer
    def functor_t
      raise NotImplementedError
    end

    # create a predicate_t
    def predicate_t
      raise NotImplementedError
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
