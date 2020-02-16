RSpec.describe Upl::Term do
  it 'parses prolog term' do
    term = Upl::Term.new 'current_prolog_flag(A,B)'

    term.atom.to_sym.should == :current_prolog_flag
    term.first.to_ruby.should be_a(Upl::Variable)
    term.last.to_ruby.should be_a(Upl::Variable)
  end

  it 'parses utf8 term' do
    term = Upl::Term.new 'string_codes("Отава ё",B)'

    term.atom.to_sym.should == :string_codes
    term.first.to_ruby.should == "Отава ё"
    term.last.to_ruby.should be_a(Upl::Variable)
  end

  it 'parses complex term' do
    term = Upl::Term.new 'string_codes("Your great length is immaterial",B), length(B,L)'

    term.atom.to_sym.should == :','

    # so long as at least some of the right bits are in the right places
    term.first.to_ruby.atom.to_sym.should == :string_codes
    term.last.to_ruby.atom.to_sym.should == :length
  end

  it 'raises prolog syntax error' do
    λ = lambda do
      # NOTE missing trailing )
      Upl::Term.new 'string_codes("Your great length is immaterial",B), length(B,L'
    end

    λ.should raise_error(RuntimeError, /syntax_error.*operator_expected/)
  end

  it 'parses operator term' do
    term = Upl::Term.new 'atom(A) =.. List'
    term.atom.to_sym.should == :'=..'
  end
end
