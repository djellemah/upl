module Upl
  class Atom
    # NOTE these are atom_t, NOT term_t and NOT Fiddle::Pointer to atom_t
    def initialize( atom_t )
      @atom_t = atom_t

      # pretty much all other methods need chars, so just do it now.
      @chars = (::Upl::Extern::PL_atom_chars @atom_t).to_s.freeze
    end

    # drop the term immediately, and just keep the atom value
    def self.of_term( term_t )
      rv = Extern::PL_get_atom term_t, (atom_t = Fiddle::Pointer[0].ref)
      rv == 1 or raise "can't get atom from term"
      new atom_t.ptr
    end

    attr_reader :atom_t

    # NOTE this returns an atom_t for obj.object_id embedded in an atom
    def self.t_of_ruby obj
      Upl::Extern.PL_new_atom "ruby-#{obj.object_id.to_s}"
    end

    # return the object_id embedded in the atom, or nil if it's not an embedded
    # object_id
    def to_obj_id
      if instance_variable_defined? :@to_obj_id
        @to_obj_id
      else
        @to_obj_id =
        if @chars =~ /^ruby-(\d+)/
          $1.to_i
        end
      end
    end

    # return the ruby object associated with the object_id embedded in the atom
    def to_ruby
      if to_obj_id
        ObjectSpace._id2ref to_obj_id
      else
        case _sym = to_sym
        when :false; false
        when :true; true
        else _sym
        end
      end
    rescue RangeError
      # object with the given obj_id no longer exists in ruby, so just return
      # the symbol with the embedded object_id.
      to_sym
    end

    def == rhs
      atom_t == rhs.atom_t
    end

    def to_sym
      @chars.to_sym
    end

    def to_s
      @chars
    end

    def inspect; to_sym end

    def pretty_print pp
      pp.text atom_t
      pp.text '-'
      pp.text to_s
    end
  end
end
