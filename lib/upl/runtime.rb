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

    def self.call st_or_term
      term =
      case st_or_term
      when String
        Term.new st_or_term
      when Term
        st_or_term
      else
        raise "dunno bout #{st_or_term}"
      end

      rv = Extern.PL_call term.term_t, Extern::NULL
      rv == 1 # don't raise
    end

    def self.ruby_free_fn
      @ruby_free_fn ||= Fiddle::Function.new Fiddle::RUBY_FREE, [Fiddle::TYPE_VOIDP], Fiddle::TYPE_VOID
    end
    end

    def self.init
      # set up no output so we don't get swipl command line interfering in ruby
      # TODO exception handling should not kick off a prolog terminal
      # TODO see gem-swipl for more useful stuff here
      args = %w[upl --tty=false --signals=false --debug=false --quiet=true]

      # convert args to char **
      ptr_size = Extern.sizeof 'char*'
      arg_ptrs = Ptr.malloc ptr_size * args.size, ruby_free_fn
      args.each_with_index do |rg,i|
        (arg_ptrs + i*ptr_size)[0,ptr_size] = Ptr[rg].ref
      end

      # call init
      rv = Extern.PL_initialise args.size, arg_ptrs
      rv == 1 or raise 'PL_initialise failed'

      # we really don't want the prolog console showing up in ruby.
      call 'set_prolog_flag(debug_on_error,false)'
    end

    # once_only. Should probably be a singleton or something.
    @inited ||= init

    def self.predicate name, arity, module_name = nil
      Extern.PL_predicate Fiddle::Pointer[name.to_s], arity, NULL
    end

    # Use prolog predicate to parse the string into a term, with its named variables as a hash of Name => _variable
    # TODO maybe use read_term_from_chars, or at least don't force the term to be an atom
    # TODO need to use read_term_from_atom('retry(A,B,C)', Term, [variable_names(VarNames)]).
    def self.term_vars st
      rv = Extern::PL_call_predicate \
        Extern::NULL, # module
        0, # flags, see PL_open_query
        (predicate 'atom_to_term', 3),
        (args = TermVector[st.to_sym, nil, nil]).terms

      vars_hash = Inter.each_of_list(args[2]).map do |term_t|
        # each of these is =(Atom,variable), and we want Atom => variable
        t = Term.new term_t
        [t.first.atom.to_sym, t.last]
      end.to_h

      return args[1], vars_hash
    end

    def self.unify( term_a, term_b )
      rv = Extern::PL_unify term_a.term_t, term_a.term_t
      rv == 1 or raise "can't unify #{term_a} and #{term_b}"
    end

    # do a query for the given term and vars, as parsed by term_vars
    def self.term_vars_query qterm, qvars_hash
      raise "not a term" unless Term === qterm
      return enum_for __method__,  qterm, qvars_hash unless block_given?

      fid_t = Extern.PL_open_foreign_frame

      begin
        # populate input values from qterm
        args = TermVector.new qterm.arity do |idx| qterm[idx] end

        # module is NULL, flags is 0
        query_id_p = Extern.PL_open_query Extern::NULL, 0, qterm.to_predicate, args.terms
        query_id_p != 0 or raise 'no space on environment stack, see SWI-Prolog docs for PL_open_query'

        loop do
          # TODO handle PL_Q_EXT_STATUS
          res = Extern.PL_next_solution query_id_p
          break if res == 0

          hash = qvars_hash.each_with_object Hash.new do |(name_sym,var),ha|
            # term_t will be invalidated by the next call to PL_next_solution,
            # so we need to construct a ruby tree of the value term
            val = ha[name_sym] = var.to_ruby
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

    def self.predicate name, arity
      pred_p = Extern.PL_predicate Ptr[name.to_s], arity, Extern::NULL
    end

    # Simple query with predicate / arity
    # Returns an array of arrays.
    def self.squery predicate_str, arity
      return enum_for :squery, predicate_str, arity unless block_given?

      p_functor = Extern::PL_new_functor predicate_str.to_sym.to_atom, arity
      p_predicate = Extern::PL_pred p_functor, Extern::NULL

      answer_lst = TermVector.new arity
      query_id_p = Extern.PL_open_query Extern::NULL, 0, p_predicate, answer_lst.terms

      loop do
        rv = Extern.PL_next_solution query_id_p
        break if rv == 0
        yield answer_lst.each_t.map{|term_t| Tree.of_term term_t}
      end

    ensure
      # NOTE this also gets called after enum_for
      query_id_p&.to_i and Extern.PL_close_query query_id_p
    end

    def self.query term
      raise "not a Term" unless Term === term
      return enum_for :query_term, term unless block_given?

      answer_lst = TermVector.new term.arity do |idx| term[idx] end
      query_id_p = Extern.PL_open_query Extern::NULL, 0, term.to_predicate, answer_lst.terms

      loop do
        rv = Extern.PL_next_solution query_id_p
        break if rv == 0
        yield answer_lst.each_t.map{|term_t| Tree.of_term term_t}
      end

    ensure
      # NOTE this also gets called after enum_for
      query_id_p&.to_i and Extern.PL_close_query query_id_p
    end
  end
end
