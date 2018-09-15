module Upl
  class Dict < Hash
    def initialize( tag, default_value = nil, &default_blk )
      @tag = tag
      super default_value, &default_blk
    end

    # fetch the tag for the dict
    def self.dict_tag( dict_term_t )
      args = Extern.PL_new_term_refs 2

      # set first arg to dict_term_t
      # TODO need a term vector for this and other places
      rv = Extern::PL_put_term args+0, dict_term_t
      rv == 1 or raise "can't assign dict_term_t"

      # TODO need a better api here as well, and other places
      rv = Extern::PL_call_predicate \
        Extern::NULL, # module
        0, # flags, see PL_open_query
        (Runtime.predicate 'is_dict', 2),
        args

      rv == 1 or raise "can't retrieve dict tag"

      # now retrieve the term's first arg's value
      Tree.of_term args+1
    end

    # copy dict_term_t into a ruby structure
    def self.of_term( dict_term_t )
      # Have to do a little hoop-jumping here. There are no c-level calls to
      # access dicts, so we have to break them down with prolog predicates. But
      # we can't process queriess that have dicts in their results, otherwise we
      # have an endless recursion.

      query_term, query_vars = Runtime.term_vars 'get_dict(K,Dict,V)'
      # So set the Dict value to dict_term_t above ...
      query_term[1] = dict_term_t
      # ...and remove it from the output variables
      query_vars.delete_at 1

      # now we have a result set with K,V values
      en = Upl::Runtime.term_vars_query query_term, query_vars

      # map to a hash-y thing
      en.each_with_object Dict.new(dict_tag dict_term_t) do |row,values|
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
