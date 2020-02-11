RSpec.describe Upl::Dict do
  it 'constructs untagged dict' do
    ary, = Array Upl.query 'Untagged = _{serious: yes, important: no, value: 0}'
    dict = ary[:Untagged]
    dict.tag.should be_a(Upl::Variable)
    dict.to_h.should == {serious: :yes, important: :no, value: 0}
  end

  it 'constructs tagged dict' do
    ary, = Array Upl.query 'Tagged = galazy{name: borogrove, value: 42, pi: 3.1415, e: 2.718281}'
    dict = ary[:Tagged]
    dict.tag.should == :galazy
    dict.to_h.should == {name: :borogrove, value: 42, pi: 3.1415, e: 2.718281}
  end

  it 'converts hash to dict term' do
    ha = {one: 1, duo: 2}
    term, vars = Upl::Runtime.term_vars 'A = Dict'
    vars[:Dict] = ha

    rv = Upl.query(term, vars).first
    rv[:A].should == ha
  end

  xit 'converts tagged hash to dict term' do
    dict = Upl::Dict.new tag: :worley, values: {tre: 3, kvr: 4}
    term, vars = Upl::Runtime.term_vars '_{tre: A} :< Dict'
    vars[:Dict] = dict
    ha = Upl.query(term,vars.first).first
    ha[:A].should == 3
  end
end
