require 'pathname'
require_relative 'upl/version'

require_relative 'upl/extern'
require_relative 'upl/term'
require_relative 'upl/variable'
require_relative 'upl/atom'
require_relative 'upl/runtime'
require_relative 'upl/tree'
require_relative 'upl/inter'

module Upl
  def self.query st, &blk
    term, vars = Runtime::term_vars st
    Runtime::term_vars_query term, vars, &blk
  end

  def self.consult filename
    p = Pathname filename
    Runtime::eval %Q{["#{p.realpath.to_s}"]}
  end
end
