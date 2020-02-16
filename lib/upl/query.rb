module Upl
  # Mostly sugar
  # TODO needs a row_proc like Sequel uses to generate the yielded values
  # TODO maybe cache @count (after first enumeration)
  class Query
    # TODO can only be string at this point
    # One-use only. If you want a new query, create another instance.
    # Is an enumerable for the result set.
    def initialize term_or_string, &map_blk
      @source = term_or_string
      @term, @vars = Upl::Runtime.term_vars term_or_string
      @map_blk = map_blk
    end

    attr_reader :source, :term, :vars

    def names; @vars.keys end

    def method_missing meth, *args, &blk
      if meth.end_with? '='
        assign = true
        name = meth[..-2].to_sym
      else
        name = meth
      end

      return super unless @vars.include? name

      if assign
        @vars[name] === args.first or raise "Unification failure"
      else
        @vars[name]
      end
    end

    def [] name; @vars[name] end

    def []= name, value
      @vars[name] === value or raise "Unification failure"
    end

    def call
      @results ||= Upl::Runtime.term_vars_query @term, @vars
    end

    def each &blk
      call.map do |row|
        # TODO this assume the if statement is faster than a call to a default ->i{i}
        if @map_blk
          blk.call @map_blk[row]
        else
          blk.call row
        end
      end
    end

    include Enumerable
  end
end
