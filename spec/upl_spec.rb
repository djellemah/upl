RSpec.describe Upl do
  it "has a version number" do
    Upl::VERSION.should_not be_nil
  end

  describe 'facts' do
    include Upl

    before :each do
      # Doesn't work.
      # tout_le_monde = Upl::Term.functor :person, *3.times.map{Upl::Variable.new.to_term}
      # Upl::Runtime.eval Upl::Term.functor :retractall, tout_le_monde
    end

    def query_str; 'person(A,B,C)' end

    it 'retrieves an objective fact' do
      fact = Upl::Term.functor :person, :john, :anderson, (obj = Object.new)
      Upl.assert fact

      ry, = Array Upl.query query_str
      ry[:A].to_sym.should == :john
      ry[:B].to_sym.should == :anderson
      ry[:C].should equal(obj)

      Upl.retract fact
    end

    it 'restricts based on objective value' do
      fact1 = Upl::Term.functor :person, :james, :madison, (thing1 = Object.new)
      Upl.assert fact1

      fact2 = Upl::Term.functor :person, :thomas, :paine, (thing2 = Object.new)
      Upl.assert fact2

      # parse the query, then unify C with thing2
      # this needs a nicer api :-\
      query_term, query_vars = Upl::Runtime.term_vars query_str
      Upl::Extern.PL_unify query_vars.last.args.to_a.last, thing2.to_term_t
      results = Array Upl::Runtime.term_vars_query query_term, query_vars

      # we have results...
      results.size.should == 1
      ry = results.first

      ry[:A].to_sym.should == :thomas
      ry[:B].to_sym.should == :paine
      ry[:C].should equal(thing2)

      Upl.retract fact2
      Upl.retract fact1
    end
  end

  describe Upl::Runtime do
    describe 'squery' do
      it 'returns values' do
        ry = Array described_class.squery :current_prolog_flag, 2
        ry.assoc(:emulated_dialect).should == [:emulated_dialect, :swi]
      end
    end
  end
end
