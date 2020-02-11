RSpec.describe Upl::Variable do
  it 'creates anonymous variable' do
    v = Upl::Variable.new
    v.term_t.should be_a(Fiddle::Pointer)
  end

  it 'creates named variable' do
    vn = Upl::Variable.new name: :A
    vn.term_t.should be_a(Fiddle::Pointer)
    vn.name.should == :A
  end

  # unification can only be testing inside of foreign calls
  # so see foreign_spec

  it 'displays clpfd attributed variables' do
    Upl::Runtime.call '[library(clpfd)]'
    term, vars = Upl::Runtime.term_vars 'A #> 2'
    en = Upl.query term, vars
    result_var = en.first[:A]

    result_var.should be_attributed

    # the attribute term has several values and I don't understand it
    result_var.attribute.args.first.should == :clpfd
  end
end
