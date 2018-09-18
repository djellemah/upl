module Upl
  module Inter
    # Try Term, then Fiddle::Pointer, then to_term_t.
    # Return a term_t pointer
    def self.term_t_of term_or_ptr
      case term_or_ptr
      when Term
        term_or_ptr.term_t
      when Fiddle::Pointer
        term_or_ptr
      else
        term_or_ptr.to_term_t
      end
    end

    # lst_term is a Term, or a Fiddle::Pointer to term_t
    # yield term_t items of the lst_term
    def self.each_of_list lst_term, &blk
      return enum_for __method__, lst_term unless block_given?
      lst_term = Inter.term_t_of lst_term

      while Extern::PL_get_nil(lst_term) != 1 # not end of list
        res = Extern::PL_get_list \
          lst_term,
          (head_t = Extern.PL_new_term_ref),
          (rst_t = Extern.PL_new_term_ref)

        break unless res == 1

        yield head_t
        lst_term = rst_t
      end
    end
  end
end

class Object
  def to_atom
    if frozen?
      # TODO must check instance variable here
      _upl_atomize
    else
      @_upl_atom ||= _upl_atomize
    end
  end

  # return a Term object from to_term_t
  def to_term
    Upl::Term.new to_term_t
  end

  # return a term_t pointer
  def to_term_t
    if frozen?
      # TODO must check instance variable here
      _upl_termize
    else
      # @_upl_termize ||= _upl_termize
      _upl_termize
    end
  end

protected

  def _upl_termize
    term_t = Upl::Extern.PL_new_term_ref
    rv = Upl::Extern.PL_put_atom term_t, to_atom
    rv == 1 or raise "can't create atom from #{self}"
    term_t
  end

  def _upl_atomize
    # TODO see also PL_agc_hook for hooking into the swipl GC
    atom_t = Upl::Extern.PL_new_atom "ruby-#{object_id.to_s}"
    ObjectSpace.define_finalizer self, &self.class._upl_finalizer_blk(atom_t)
    atom_t
  end

  # Have to put this in a separate method, otherwise the finalizer block's
  # binding holds onto the obj it's trying to finalize.
  def self._upl_finalizer_blk atom_t
    proc do |objid| Upl::Extern.PL_unregister_atom atom_t end
  end
end

class Symbol
  def to_atom
    Upl::Extern.PL_new_atom to_s
  end
end
