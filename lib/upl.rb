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
  def self.query st, &blk
    term, vars = Runtime::term_vars st
    Runtime::term_vars_query term, vars, &blk
  end

  def self.consult filename
    p = Pathname filename
    Runtime::call %Q{["#{p.realpath.to_s}"]}
  end

  def self.assert term
    Runtime.eval Term.functor :assert, term
  end

  def self.retract term
    Runtime.call Term.functor :retract, term
  end
end
