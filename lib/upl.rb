require 'pathname'
require_relative 'upl/version'

require_relative 'upl/extern'
require_relative 'upl/term'
require_relative 'upl/variable'
require_relative 'upl/variables'
require_relative 'upl/atom'
require_relative 'upl/runtime'
require_relative 'upl/dict'
require_relative 'upl/tree'
require_relative 'upl/inter'
require_relative 'upl/term_vector'
require_relative 'upl/foreign'
require_relative 'upl/query'

module Upl
  # You probably want to use Query.new instead of this.
  # an enumerator yielding hashes keyed by the variables, mapping to the term
  module_function def query string_or_term, vars = nil, &blk
    if string_or_term.is_a?(Term) && vars
      Runtime.term_vars_query string_or_term, vars
    else
      case string_or_term
      when Term
        # TODO this returns an array of values without variable names.
        # So it doesn't really belong here.
        Runtime.query string_or_term
      when String
        term, vars = Runtime.term_vars string_or_term
        Runtime.term_vars_query term, vars, &blk
      else
        raise "dunno about #{string_or_term.inspect}"
      end
    end
  end

  # For semidet predicates, ie that have only one result.
  # You have to extract values using Upl::Variable#to_ruby.
  module_function def call term
    Runtime::call term
  end

  module_function def consult filename
    p = Pathname filename
    Runtime::call %Q{["#{p.realpath.to_s}"]}
  end

  # Nicer syntax for Term.functor. Construct a Term from a symbol and args that
  # all respond to 'to_term_t'.
  #
  # In other words:
  #
  #   Upl.query 'current_prolog_flag(A,B)'
  #
  # is similar to
  #
  #   Upl.query Term :current_prolog_flag, Variable.new, Variable.new
  #
  module_function def Term name, *args
    Term.predicate name, *args
  end

  module_function def asserta term
    Runtime.call Term :asserta, term
  end

  module_function def assertz term
    Runtime.call Term :assertz, term
  end

  # behaves as if run under once, cos of the way call works
  module_function def retract term
    Runtime.call Term :retract, term
  end

  module_function def listing
    (Upl.query 'with_output_to(string(Buffer),listing)').first[:Buffer]
  end
end
