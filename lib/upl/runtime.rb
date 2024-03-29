require 'fiddle'
require 'pp'

require_relative 'extern'

# TODO move this to inter, or maybe a refinement
class Fiddle::Pointer
  def term_type
    ::Upl::Extern.PL_term_type self
  end

  def type_string
    type_int = term_type
    ::Upl::Extern.constants.find{|c| (::Upl::Extern.const_get c) == type_int} || type_int
  end
end

module Upl
  module Runtime
    # shortcuttery
    Ptr = Fiddle::Pointer

    class PrologException < RuntimeError
      def initialize(term_tree)
        @term_tree = term_tree
      end

      def message
        @message ||= begin
          # TODO need to use print_message_lines/3 to generate this string
          pp = PP.new
          @term_tree.args.each{|arg| arg.pretty_print pp}
          "#{@term_tree.atom}: #{pp.output}"
        end
      end
    end

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

      rv = Extern.PL_call term.term_t, Fiddle::NULL
      rv == 1 # don't raise
    end

    def self.init
      # set up no output so we don't get swipl command line interfering in ruby
      # TODO exception handling should not kick off a prolog terminal
      # TODO from gem-swipl args = [ @swipl_lib, "-tty", "-q", "-t", "true", "-g", "true", "--nodebug", "--nosignals" ]
      args = %w[upl --tty=false --signals=false --debug=false --quiet=true]

      # convert args to char **
      # TODO Fiddle::SIZEOF_VOIDP would be faster
      ptr_size = Extern.sizeof 'char*'
      arg_ptrs = Ptr.malloc ptr_size * args.size, Extern::ruby_free_fn
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
    @_upl_runtime ||= init

    def self.predicate name, arity, module_name = 0
      Extern.PL_predicate Ptr[name.to_s], arity, Fiddle::Pointer[module_name]
    end

    def self.unify( term_a, term_b )
      rv = Extern::PL_unify term_a.term_t, term_a.term_t
      rv == 1 or raise "can't unify #{term_a} and #{term_b}"
    end

    # blk takes a fid_t
    def self.with_frame &blk
      fid_t = Extern.PL_open_foreign_frame
      yield fid_t
    ensure
      # discards term references, but keeps bindings
      # fid_t and Extern.PL_close_foreign_frame fid_t
      # same as close and also undo bindings
      fid_t and Extern.PL_discard_foreign_frame fid_t
    end

    # Use prolog predicate to parse the string into a term (containing variables), along with its named
    # variables as a hash of Name => _variable
    #
    # TODO need to use read_term_from_atom('pred(A,B,C)', Term, [variable_names(VarNames)]).
    # remember Atom can also be a string for swipl
    def self.term_vars st
      rv = Extern::PL_call_predicate \
        Fiddle::NULL, # module
        0, # flags, see PL_open_query
        (predicate 'atom_to_term', 3),
        # 3 variables, first one determined
        (args = TermVector[st.to_sym, nil, nil]).terms

      vars = Inter.each_of_list(args[2]).each_with_object Variables.new do |term_t, vars|
        # each of these is =(Atom,variable), and we want Atom => variable
        t = Term.new term_t
        vars.store t.first.atom.to_sym, (Variable.new t.last.term_t, name: t.first.atom.to_sym)
      end

      # return term, {name => var...}
      return args[1], vars
    end

    # just to make sure the query handle pointer is properly closed
    # TODO should be private, because args are gnarly
    def self.open_query qterm, mod: nil, flags: nil, &blk
      # This will need a string for the module, eventually
      # module is NULL, flags is 0
      mod ||= Fiddle::NULL
      flags ||= flags=Extern::Flags::PL_Q_EXT_STATUS | Extern::Flags::PL_Q_CATCH_EXCEPTION
      args = TermVector.new qterm.arity do |idx| qterm[idx] end

      query_id_p = Extern.PL_open_query mod, flags, qterm.to_predicate, args.terms
      query_id_p != 0 or raise 'no space on environment stack, see SWI-Prolog docs for PL_open_query'

      yield query_id_p
    ensure
      query_id_p&.to_i and Extern.PL_close_query query_id_p
    end

    def self.raise_prolog_or_ruby query_id_p
      tree = Tree.of_term Extern::PL_exception(query_id_p)

      case tree.atom.to_ruby
      # special case for errors that originated inside a predicate
      # that was defined in ruby.
      when :ruby_error
        # re-raise the actual exception object from the predicate
        raise tree.args.first
      else
        raise PrologException, tree
      end
    end

    # Do a query for the given term and vars, as parsed by term_vars.
    # qvars_hash is a hash of :VariableName => Term(PL_VARIABLE)
    # and each variable is already bound in qterm.
    # TODO much duplication between this and .query below
    def self.query qterm, qvars_hash = nil
      raise "not a term" unless Term === qterm
      return enum_for __method__,  qterm, qvars_hash unless block_given?

      result_map =
      if qvars_hash
        lambda do
          # construct map of given variable names to their values
          qvars_hash.each_with_object Hash.new do |(name_sym,var),ha|
            ha[name_sym] = var.to_ruby
          end
        end
      else
        # no variable names provided so just get the values
        ->{ qterm.map{|term_t| Tree.of_term term_t} }
      end

      open_query qterm do |query_id_p|
        loop do
          case (status = Extern.PL_next_solution query_id_p)
          when Extern::ExtStatus::FALSE
            break

          when Extern::ExtStatus::EXCEPTION
            raise_prolog_or_ruby query_id_p

          when Extern::ExtStatus::TRUE, Extern::ExtStatus::LAST
            # var will be invalidated by the next call to PL_next_solution,
            # so we need to construct a ruby tree copy of the value term immediately.
            yield result_map[]

          else
            raise "unknown PL_next_solution status #{status}"
          end
        end
      end
    end
  end
end
