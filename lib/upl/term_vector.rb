require 'fiddle'

module Upl
  # Create a c-array of terms using PL_new_term_refs. Methods on this class
  # will return the term_t pointers wrapped in Term objects. If you want access
  # to the underlying term_t pointers, use terms + idx, or the term_t method of
  # the Term objects.
  class TermVector
    # args must all be convertible to term_t Fiddle::Pointers, via term_t_of.
    #
    # nil values are defaulted to Variable.new, but beware passing in the wrong
    # number of arguments.
    def self.[]( *args )
      new args.size do |idx|
        args[idx]
      end
    end

    # similar to Array.new, but each value yielded from blk will be converted to
    # term_t using term_t_of
    def initialize size, &blk
      @size = Integer size
      @terms = Extern.PL_new_term_refs @size

      if block_given?
        @size.times do |idx|
          termable = (yield idx) || Variable.new
          term_t = Inter.term_t_of termable
          # TODO not sure if Extern::PL_put_term should be available as a possibility here?
          rv = Extern::PL_unify @terms+idx, term_t
          rv == 1 or raise "can't set index #{idx} of term_vector to #{termable}"
        end
      end
    end

    attr_reader :size, :terms

    def each_t
      return enum_for :each_t unless block_given?
      size.times.each do |idx| yield @terms+idx end
    end

    def each
      return enum_for :each unless block_given?
      size.times.each do |idx| yield Term.new @terms+idx end
    end

    include Enumerable

    def first; Term.new @terms+0; end
    def last; Term.new @terms+(size-1); end

    def [](idx)
      raise IndexError unless idx < @size
      Term.new @terms+idx
    end

    def []=(idx, value)
      raise IndexError unless idx < @size
      Extern::PL_put_term @terms + idx, (Inter.term_t_of value)
    end

    def to_a
      size.times.map{|idx| @terms+idx}
    end
  end
end
