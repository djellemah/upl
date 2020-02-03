RSpec.describe Upl::Foreign do
  describe 'register_semidet' do
    it 'single variable' do
      Upl::Foreign.register_semidet :single_variable do |arg0|
        arg0.unify :wut
      end

      rv = Upl.query('single_variable(A)').first
      rv[:A].should == :wut
    end

    it 'input and output variables' do
      Upl::Foreign.register_semidet :special_concat do |arg0, arg1|
        arg1.unify "#{arg0}-special"
      end

      rv = Upl.query('special_concat("hello", A)').first
      rv[:A].should == "hello-special"
    end

    it 'several variables' do
      Upl::Foreign.register_semidet :spread_ary do |ary, var1, var2, var3|
        var1.unify ary[0]
        var2.unify ary[1]
        var3.unify ary[2]
      end

      rv = Upl.query('spread_ary([1,2,3], A, B, C)').first
      rv[:A].should == 1
      rv[:B].should == 2
      rv[:C].should == 3
    end

    it 'failure' do
      Upl::Foreign.register_semidet :single_variable do |arg0|
        arg0.unify :wut
        false
      end

      Upl.query('single_variable(A)').to_a.should == []
    end

    # TODO needs the better query api
    it 'method call'

    it 'overwrite predicate' do
      Upl::Foreign.register_semidet(:overwrite) {|var1| var1.unify :first }
      Upl::Foreign.register_semidet(:overwrite) {|var1| var1.unify :second }

      rv = Upl.query('overwrite(A)').first
      rv[:A].should == :second
    end

    it 'exceptions' do
      Upl::Foreign.register_semidet :oops do |arg0, arg1|
        raise "arg0 not determined" if Upl::Variable === arg0
      end

      ->{Upl.query('oops(_, _)').to_a}.should raise_error(RuntimeError, /not determined/)
    end
  end
end
