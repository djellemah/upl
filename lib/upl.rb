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

module Upl
  def self.query string_or_term, &blk
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

  def self.consult filename
    p = Pathname filename
    Runtime::call %Q{["#{p.realpath.to_s}"]}
  end

  def self.asserta term
    Runtime.call Term.functor :asserta, term
  end

  def self.assertz term
    Runtime.call Term.functor :assertz, term
  end

  # behaves as if run under once, cos of the way call works
  def self.retract term
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
  def self.Term name, *args
    Term.functor name, *args
  end
end
