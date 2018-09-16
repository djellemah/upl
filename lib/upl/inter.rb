# TODO not used
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
    Term.new to_term_t
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
    # see also PL_agc_hook for hooking into the swipl GC
    ObjectSpace.define_finalizer self do |this_obj|
      # TODO PL_unregister_atom? Finalizer?
      Upl::Extern.PL_unregister_atom this_obj.instance_variable_get :@_upl_atom
    end
    Upl::Extern.PL_new_atom "ruby-#{object_id.to_s}"
  end
end

class Symbol
  def to_atom
    Upl::Extern.PL_new_atom to_s
  end
end

module Inter
end
