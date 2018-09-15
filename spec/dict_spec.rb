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

  it 'converts to dict term'
end
