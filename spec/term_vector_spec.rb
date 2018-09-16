RSpec.describe Upl::TermVector do
  it 'constructs variables from nil' do
    tv = described_class[nil, nil, nil]
    tv.size.should == 3
    tv.each do |term|
      term.tree.should be_a(Upl::Variable)
    end
  end

  it 'constructs variables from size' do
    tv = described_class.new 4
    tv.size.should == 4
    tv.each do |term|
      term.tree.should be_a(Upl::Variable)
    end
  end

  it 'constructs terms from values' do
    tv = described_class[:hello, :there]
    tv.size.should == 2
    tv.each do |term|
      term.term_t.type_string.should == :PL_ATOM
      term.tree.should be_a(Symbol)
    end
  end

  it 'constructs from a block' do
    ary = %i[one due tre]
    tv = described_class.new(3){|idx| ary[idx]}
    tv.each do |term|
      term.term_t.type_string.should == :PL_ATOM
      term.tree.should be_a(Symbol)
    end
  end

  it 'assigns a term' do
    tv = described_class.new 3
    tv[1] = :atomic_failure

    tv.first.tree.should be_a(Upl::Variable)
    tv[1].term_t.type_string.should == :PL_ATOM
    tv.last.tree.should be_a(Upl::Variable)
  end
end
