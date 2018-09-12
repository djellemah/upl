module Upl
  class Atom
    def initialize( atom_ref )
      @atom_ptr = atom_ref.ptr
      atom_chars_ptr = ::Upl::Extern::PL_atom_chars @atom_ptr
      @_symbol = atom_chars_ptr.to_s.to_sym
    end

    # drop the term immediately, and just keep the atom pointer
    def self.of_term( term_t )
      rv = Extern::PL_get_atom term_t, (atom_ref = Fiddle::Pointer.new(0).ref)
      raise "can't get atom from term" unless rv == 1
      new atom_ref
    end

    attr_reader :atom_ptr

    def == rhs
      to_sym == rhs.to_sym
    end

    def to_sym
      @_symbol or raise "no symbol for atom"
    end

    def to_s
      @_string ||= to_sym.to_s
    end

    def inspect; to_sym end

    def pretty_print pp
      pp.text to_s
    end
  end
end
