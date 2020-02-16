describe Upl::Runtime do
  describe 'squery' do
    it 'returns values' do
      ry = Array described_class.squery :current_prolog_flag, 2
      ry.assoc(:emulated_dialect).should == [:emulated_dialect, :swi]
    end
  end

  describe 'variables' do
    it 'creates and unifies query variables' do
      query_term, query_vars = Upl::Runtime.term_vars 'current_prolog_flag(K,V)'
      query_vars.K = :emulated_dialect
      results = Upl.query(query_term, query_vars).first
      results.should == {:K=>:emulated_dialect, :V=>:swi}
    end
  end

  describe 'query' do
    it 'term only' do
      en = Upl.query Upl::Term(:current_prolog_flag, Upl::Variable.new, Upl::Variable.new)
      ary = en.to_a
      # just choose one of the values here
      ary.assoc(:toplevel_extra_white_line).should == [:toplevel_extra_white_line, true]
    end

    it 'term with variables'
    it 'string'
  end
end
