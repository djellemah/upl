module Upl
  class Dict < Hash
    def initialize( tag: nil, values: nil, default_value: nil, &default_blk )
      @tag = tag
      super default_value, &default_blk
      replace values if values
    end

    # fetch the tag for the dict
    def self.dict_tag( dict_term_t )
      args = TermVector[dict_term_t, nil]

      # TODO need a better api here as well, and other places
      # eg, need to check that args.size == predicate.arity
      # otherwise segfaults and other weird stuff ensue
      rv = Extern::PL_call_predicate \
        Extern::NULL, # module
        0, # flags, see PL_open_query
        (Runtime.predicate 'is_dict', args.size),
        args.terms

      rv == 1 or raise "can't retrieve dict tag"

      # now retrieve the variable's value
      args.last.to_ruby
    end

    # copy dict_term_t into a ruby structure
    def self.of_term( dict_term_t )
      # Have to do a little hoop-jumping here. There are no c-level calls to
      # access dicts, so we have to break them down with prolog predicates.

      query_term, query_hash = Runtime.term_vars 'get_dict(K,Dict,V)'

      # So set the Dict value to dict_term_t above ...
      query_term[1] = dict_term_t
      # ...and remove it from the output variables
      query_hash.delete :Dict

      # now we have a result set with K,V values
      en = Upl::Runtime.term_vars_query query_term, query_hash

      # map to a hash-y thing
      en.each_with_object Dict.new(tag: dict_tag(dict_term_t)) do |row,values|
        values[row[:K]] = row[:V]
      end
    end

    attr_reader :tag, :values

    def == rhs
      [tag,to_h] == [rhs.tag,rhs.to_h]
    end

    def pretty_print pp
      tag.pretty_print pp
      super
    end
  end
end
