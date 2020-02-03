module Upl
  # Storage from variables, where setting one just calls unify on the underlying terms.
  # Cos it's hard to hang unify on a single variable.
  class Variables < Hash
    def initialize *names
      super
      names.each do |name|
        self.store name, Variable.new
      end
    end

    #  calls unify, so you can't set a given variable more than once.
    def []=( name, term )
      Extern::PL_unify self[name.to_sym].to_term_t, term.to_term_t
    end

    def method_missing meth, *args
      # unfreeze
      name = meth.to_s.dup

      the_method =
      if name.chomp! '='
        # set the value
        :'[]='
      else
        # fetch the value
        :'[]'
      end

      var_name = name.to_sym

      if has_key? var_name
        send the_method, var_name, *args
      else
        super
      end
    end

    def pretty_print pp
      transform_values{|v| v.to_ruby}.pretty_print pp
    end
  end
end
