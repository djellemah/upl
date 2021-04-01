RSpec.describe Upl::Query do
  it 'set variable' do
    q = Upl::Query.new 'current_prolog_flag(K,V)'
    q.K = :emulated_dialect
    q.first.should == {:K=>:emulated_dialect, :V=>:swi}
  end

  it 'map blk' do
    q = Upl::Query.new 'current_prolog_flag(K,V)' do |ha|
      {ha[:K] => ha[:V]}
    end

    q.K = :emulated_dialect

    q.first.should == {:emulated_dialect => :swi}
  end

  it 'map blk with lowercase vars to keyword params' do
    q = Upl::Query.new 'current_prolog_flag(_k,_v)' do |_k:, _v:|
      {_k => _v}
    end

    q._k = :emulated_dialect

    q.first
    q.first.should == {:emulated_dialect => :swi}
  end

  it 'map blk with lowercase vars to single hash' do
    q = Upl::Query.new 'current_prolog_flag(_k,_v)' do |row|
      {row[:_k] => row[:_v]}
    end

    q._k = :emulated_dialect

    q.first
    q.first.should == {:emulated_dialect => :swi}
  end

  it 'unification failure' do
    q = Upl::Query.new 'current_prolog_flag(K,V)'
    q.K = :emulated_dialect
    q.first.should == {:K=>:emulated_dialect, :V=>:swi}
    ->{q.K = :something_else}.should raise_error(/unification/i)
  end

  it 'frames' do
    q = Upl::Query.new 'current_prolog_flag(K,V)'

    # rewind after frame
    Upl::Runtime.with_frame do
      q.K = :emulated_dialect
      q.first.should == {:K=>:emulated_dialect, :V=>:swi}
    end
    q.K = :toplevel_mode
    q.first.should == {:K=>:toplevel_mode, :V=>:backtracking}
  end

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
