module Upl
  # Really this is just an empty term.
  class Variable
    def initialize term_t = nil, name: nil
      @term_t = term_t || self.class.to_term
      @name = name
    end

    attr_reader :term_t, :name
    alias to_term_t term_t

    # create a ruby represetation of the term_t
    def to_ruby; Tree.of_term term_t end

    def self.copy term_t
      inst = new term_t

      inst.attributed? and inst.attribute
      inst.to_s

      inst
    end

    # bit of a hack to create empty variables for a functor
    def self.to_term
      Extern.PL_new_term_ref
    end

    def self.[]( *names )
      vars = names.map{|name| new name: name}
      if vars.size == 1 then vars.first else vars end
    end

    def to_s; _string end

    def _string
      @_string ||= begin
        Extern::PL_get_chars \
          term_t,
          (str_ref = Runtime::Ptr[0].ref),
          Extern::Convert::CVT_VARIABLE | Extern::Convert::REP_UTF8 | Extern::Convert::BUF_MALLOC # | Extern::CVT_ALL

        str_ref.ptr.free = Runtime.swipl_free_fn
        str_ref.ptr.to_s
      end
    end

    def attributed?
      if instance_variable_defined? :@attributed
        @attributed
      else
        @attributed = (Extern::PL_is_attvar term_t) == 1
      end
    end

    def attribute
      @attribute ||= begin
        rv = Extern::PL_get_attr term_t, (val = Extern.PL_new_term_ref)
        rv == 1 or raise "can't get attribute for variable"
        Tree.of_term val
      end
    end

    def pretty_print pp
      if attributed?
        attribute.pretty_print pp
      else
        if name
          pp.text name
          pp.text '='
        end
        pp.text to_s
      end
    end
  end
end
