require 'pathname'
require_relative 'upl/version'

require_relative 'upl/extern'
require_relative 'upl/term'
require_relative 'upl/variable'
require_relative 'upl/atom'
require_relative 'upl/runtime'
require_relative 'upl/dict'
require_relative 'upl/tree'
require_relative 'upl/inter'
require_relative 'upl/term_vector'
require_relative 'upl/foreign'

module Upl
  module_function def query string_or_term, &blk
    case string_or_term
    when Term
      Runtime.query string_or_term
    when String
      term, vars = Runtime.term_vars string_or_term
      Runtime.term_vars_query term, vars, &blk
    else
      raise "dunno about #{string_or_term.inspect}"
    end
  end

  module_function def consult filename
    p = Pathname filename
    Runtime::call %Q{["#{p.realpath.to_s}"]}
  end

  module_function def asserta term
    Runtime.call Term.functor :asserta, term
  end

  module_function def assertz term
    Runtime.call Term.functor :assertz, term
  end

  # behaves as if run under once, cos of the way call works
  module_function def retract term
    Runtime.call Term.functor :retract, term
  end

  def self.listing
    (Upl.query 'with_output_to(string(Buffer),listing)').first[:Buffer]
  end

  # Nicer syntax for Term.functor. Construct a Term from a symbol and args that
  # all respond to 'to_term_t'.
  #
  # In other words:
  #
  #   Upl.query 'current_prolog_flag(A,B)'
  #
  # is moreorless the same as
  #
  #   Upl.query Term :current_prolog_flag, Variable.new, Variable.new
  #
  module_function def Term name, *args
    Term.functor name, *args
  end
end
