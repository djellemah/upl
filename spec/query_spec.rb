RSpec.describe Upl::Query do
  it 'set variable' do
    q = Upl::Query.new 'current_prolog_flag(K,V)'
    q.K = :emulated_dialect
    q.first.should == {:K=>:emulated_dialect, :V=>:swi}
  end

  it 'unification failure'

  it 'single result' do
    q = Upl::Query.new 'current_prolog_flag(toplevel_mode,V)'
    q.first[:V].should == :backtracking
    q.count.should == 1
  end

  xit 'term only' do
    q = Upl::Query.new Upl::Term(:current_prolog_flag, Upl::Variable.new, Upl::Variable.new)
    ary = q.to_a
    # just choose one of the values here
    ary.assoc(:toplevel_extra_white_line).should == [:toplevel_extra_white_line, true]
  end

  it 'many results' do
    q = Upl::Query.new 'current_prolog_flag(K,V)'
    ary = q.map{|ha| [ha[:K],ha[:V]]}

    # just choose one of the values here
    ary.assoc(:toplevel_extra_white_line).should == [:toplevel_extra_white_line, true]
  end
end
