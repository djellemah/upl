RSpec.describe Upl do
  it "has a version number" do
    Upl::VERSION.should_not be_nil
  end

  describe 'facts' do
    include Upl

    before :each do
      # Doesn't work.
      # tout_le_monde = Upl::Term.functor :person, *3.times.map{Upl::Variable.new.to_term}
      # Upl::Runtime.call Upl::Term.functor :retractall, tout_le_monde
    end

    it 'retrieves an objective fact' do
      fact = Upl::Term.functor :person, :john, :anderson, (obj = Object.new)
      Upl.assertz fact

      ry, = Array Upl.query 'person(A,B,C)'
      ry[:A].to_sym.should == :john
      ry[:B].to_sym.should == :anderson
      ry[:C].should equal(obj)

      Upl.retract fact
    end

    it 'restricts based on objective value' do
      fact1 = Upl::Term.functor :person, :james, :madison, (thing1 = Object.new)
      Upl.assertz fact1

      fact2 = Upl::Term.functor :person, :thomas, :paine, (thing2 = Object.new)
      Upl.assertz fact2

      # parse the query, then unify C with thing2
      # TODO this needs a nicer api :-\
      # TODO maybe use one object instead of two, and that one object has a .execute method as well as named variable setters?
      query_term, query_vars = Upl::Runtime.term_vars 'person(A,B,C)'
      query_vars.C = thing2
      results = Array Upl.query query_term, query_vars

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

    describe 'variables' do
      it 'creates and unifies query variables' do
        query_term, query_vars = Upl::Runtime.term_vars 'current_prolog_flag(K,V)'
        query_vars.K = :emulated_dialect
        results = Upl.query(query_term, query_vars).first
        results.should == {:K=>:emulated_dialect, :V=>:swi}
      end
    end
  end
end
