require 'fiddle'

require_relative 'extern'

class Fiddle::Pointer
  def term_type
    ::Upl::Extern.PL_term_type self
  end

  def type_string
    type_int = term_type
    ::Upl::Extern.constants.find{|c| (::Upl::Extern.const_get c) == type_int}
  end
end

module Upl
  module Runtime
    Ptr = Fiddle::Pointer

    def self.init
      # set up no output so we don't get swipl command line interfering in ruby
      # TODO exception handling should not kick off a prolog terminal
      # TODO see gem-swipl for more useful stuff here
      args = %w[upl -q --tty=false --nosignals]

      # convert args to char **
      ptr_size = Extern.sizeof 'char*'
      arg_ptrs = Ptr.malloc(ptr_size * args.size)
      args.each_with_index do |rg,i|
        (arg_ptrs + i*ptr_size)[0,ptr_size] = Ptr[rg].ref
      end

      # call init
      rv = Extern.PL_initialise args.size, arg_ptrs
      rv == 1 or raise 'PL_initialise failed'
    end

    # once_only. Should probably be a singleton or something.
    @inited ||= init

    def self.predicate name, arity, module_name = nil
      Extern.PL_predicate Fiddle::Pointer[name.to_s], arity, NULL
    end

    # Use prolog predicate to parse the string into a term with its named variables
    def self.term_vars st
      # atom_to_term('your_pred(A,B,C,D)',Term,Options).
      terms = Extern.PL_new_term_refs 3
      atom, term, options = terms+0, terms+1, terms+2

      Extern::PL_put_atom atom, (Extern::PL_new_atom Fiddle::Pointer[st])
      Extern::PL_put_variable term
      Extern::PL_put_variable options

      # docs say to use read_term_from_atom/3, but it fails with uninstantiated variables for 7.7.18
      rv = Extern::PL_call_predicate \
        Extern::NULL, # module
        0, # flags, see PL_open_query
        (predicate 'atom_to_term', 3),
        terms

      # first must be Term.new otherwise Term unhooks the term_t pointer
      # vars *must* be unhooked though ¯\_(ツ)_/¯
      return (Term.new term), (list_to_ary options do |elt| Term.new elt end)
    end

    def self.unify( term_a, term_b )
      rv = Extern::PL_unify term_a.term_t, term_a.term_t
      rv == 1 or raise "can't unify #{term_a} and #{term_b}"
    end

    # do a query for the given term and vars, as parsed by term_vars
    def self.term_vars_query qterm, qvars
      raise "not a term" unless Term === qterm
      return enum_for __method__,  qterm, qvars unless block_given?

      fid_t = Extern.PL_open_foreign_frame

      begin
        # input values
        terms_ptr = Extern.PL_new_term_refs qterm.arity
         qterm.args.each_with_index do |arg,idx|
          Extern::PL_unify (terms_ptr+idx), arg
        end

        # module is NULL, flags is 0
        query_id_p = Extern.PL_open_query Extern::NULL, 0, qterm.to_predicate, terms_ptr
        query_id_p != 0 or raise 'no space on environment stack, see SWI-Prolog docs for PL_open_query'

        loop do
          # TODO handle PL_Q_EXT_STATUS
          res = Extern.PL_next_solution query_id_p
          break if res == 0

          hash = qvars.each_with_object Hash.new do |name_var,ha|
            name_term_t, var_term_t = name_var.args.to_a
            name = Term.new name_term_t

            # term_t will be invalidated by the next call to PL_next_solution,
            # so we need to construct a ruby tree of the value term
            val = ha[name.atom.to_sym] = Tree.of_term var_term_t
            # binding.pry if val.to_sym == :query_debug_settings rescue false
          end

          yield hash
        end

      ensure
        query_id_p&.to_i and Extern.PL_close_query query_id_p
      end

    ensure
      # this also gets called after enum_for, so test for fid_t
      fid_t and Extern.PL_close_foreign_frame fid_t
    end

    def self.eval st_or_term
      p_term =
      case st_or_term
      when String
        rv = Extern.PL_chars_to_term Fiddle::Pointer[st_or_term], (p_term = Extern.PL_new_term_ref)
        raise "failure parsing term #{st_or_term}" unless rv == 1
        p_term
      when Term
        st_or_term.term_t
      else
        raise "dunno bout #{st_or_term}"
      end

      rv = Extern.PL_call p_term, Extern::NULL
      rv == 1 or raise "failure executing term #{st}"
    end

    def self.predicate name, arity
      pred_p = Extern.PL_predicate Ptr[name.to_s], arity, Extern::NULL
    end

    def self.list_to_ary lst, &elt_converter
      rv = []

      while Extern::PL_get_nil(lst) != 1 # not end of list
        res = Extern::PL_get_list \
          lst,
          (head = Extern.PL_new_term_ref),
          (rst = Extern.PL_new_term_ref)

        break unless res == 1

        rv << (elt_converter.call head)
        lst = rst
      end

      rv
    end

    # simple query with predicate / arity
    def self.squery predicate_str, arity
      return enum_for :squery, predicate_str, arity unless block_given?
      p_atom = Extern::PL_new_atom Fiddle::Pointer[predicate_str]
      p_functor = Extern::PL_new_functor p_atom, arity
      p_predicate = Extern::PL_pred p_functor, Extern::NULL

      answer_lst = Extern.PL_new_term_refs arity
      query_id_p = Extern.PL_open_query Extern::NULL, 0, p_predicate, answer_lst

      loop do
        res = Extern.PL_next_solution query_id_p
        break if res == 0

        answrs =
        arity.times.map do |i|
          term_to_ruby answer_lst+i
        end

        yield answrs
      end

    ensure
      # NOTE this also gets called after enum_for
      query_id_p&.to_i and Extern.PL_close_query query_id_p
    end
  end
end
