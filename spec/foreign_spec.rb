RSpec.describe Upl::Foreign do
  describe 'register_semidet' do
    it 'single variable' do
      Upl::Foreign.register_semidet :single_variable do |arg0|
        arg0 === :wut
      end

      rv = Upl.query('single_variable(A)').first
      rv[:A].should == :wut
    end

    it 'input and output variables' do
      Upl::Foreign.register_semidet :special_concat do |arg0, arg1|
        arg1 === "#{arg0}-special"
      end

      rv = Upl.query('special_concat("hello", A)').first
      rv[:A].should == "hello-special"
    end

    it 'utf8 conversion' do
      Upl::Foreign.register_semidet :sailing do |arg0|
        arg0 === "And the ʃip sailed ðere"
      end

      rv = Upl.query('sailing(X)').first
      rv[:X].should == "And the ʃip sailed ðere"
    end

    it 'several variables' do
      Upl::Foreign.register_semidet :spread_ary do |ary, var1, var2, var3|
        # TODO what happens when an early unification fails? Specific Exception?
        var1 === ary[0]
        var2 === ary[1]
        var3 === ary[2]
      end

      rv = Upl.query('spread_ary([1,2,3], A, B, C)').first
      rv[:A].should == 1
      rv[:B].should == 2
      rv[:C].should == 3
    end

    it 'failure' do
      Upl::Foreign.register_semidet :single_variable do |arg0|
        arg0 === :wut
        false
      end

      Upl.query('single_variable(A)').to_a.should == []
    end

    # Testing variable unification without a register_semidet is really hard. So
    # leave this spec in here.
    it 'non-unification' do
      Upl::Foreign.register_semidet :single_variable do |arg0|
        arg0 === :wut
        arg0 === :other_thing
      end

      Upl.query('single_variable(A)').to_a.should == []
    end

    it 'overwrite predicate' do
      Upl::Foreign.register_semidet(:overwrite) {|var1| var1 === :first }
      Upl::Foreign.register_semidet(:overwrite) {|var1| var1 === :second }

      rv = Upl.query('overwrite(A)').first
      rv[:A].should == :second
    end

    it 'RuntimeError' do
      Upl::Foreign.register_semidet :oops do |arg0, arg1|
        raise "arg0 not determined" if Upl::Variable === arg0
      end

      ->{Upl.query('oops(_, _)').to_a}.should raise_error(RuntimeError, /not determined/)
    end

    it 'ruby syntax error' do
      Upl::Foreign.register_semidet :syntax_oops do |arg0, arg1|
        arg3 === arg4
      end

      # note NameError
      ->{Upl.query('syntax_oops(_, _)').to_a}.should raise_error(NameError, /undefined local variable or method `arg3'/)
    end

    it 'prolog error' do
      Upl::Foreign.register_semidet :ary do |arg0|
        arg0 === []
      end

      ->{Upl.query('ary(A),A').to_a}.should raise_error(Upl::Runtime::PrologException, /error: existence_error\/2\(:procedure/)
    end

    it 'cloning of query_vars from parsed statement'

    # For calling methods on ojects from prolog
    describe 'mcall' do
      it 'method call' do
        query_term, query_vars = Upl::Runtime.term_vars 'mcall(Obj,voicemail,Value)'
        def (obj = Object.new).voicemail
          "Call yer logs, mate!"
        end

        query_vars.Obj = obj
        rv = Array Upl::Runtime.query query_term, query_vars
        rv.first[:Value].should == "Call yer logs, mate!"
      end

      it 'value conversion' do
        query_term, query_vars = Upl::Runtime.term_vars <<~prolog
          mcall(Obj,voicemail,Value), string_codes(Value,Co)
        prolog

        def (obj = Object.new).voicemail
          "Approximate Characters"
        end

        query_vars.Obj = obj
        rv = Array Upl::Runtime.query query_term, query_vars
        rv.first[:Co].should == obj.voicemail.each_codepoint.to_a
      end

      # TODO needs the better query api
      it 'better method call'

      it 'functor method call' do
        # not implemented yet
        def (obj = Object.new).voicemail; "Call yer logs, mate!" end
        term = Upl::Term :mcall, obj, :voicemail, (val = Upl::Variable[:Value])

        obj2, sym, str = Upl.query(term).first

        obj2.should == obj
        sym.should == :voicemail
        str.should == "Call yer logs, mate!"
      end

      it 'term method call' do
        obj = Object.new
        def obj.to_s; "This is from Ruby, with Love :-D" end

        vars = Upl::Variables.new :Value
        term = Upl::Term :mcall, obj, :to_s, vars.Value
        en = Upl::Runtime.query term, vars
        en.first[:Value].should == obj.to_s
      end

      it 'term method call lowercase value' do
        obj = Object.new
        def obj.to_s; "this is from ruby, with love :-p" end

        vars = Upl::Variables.new :value
        term = Upl::Term :mcall, obj, :to_s, vars.value
        en = Upl::Runtime.query term, vars
         # TODO update api to have en.first.value
        en.first[:value].should == obj.to_s
      end
    end
  end

  describe 'register_nondet' do
    it 'output only' do
      class SymbolIterator
        def initialize
          @en = ObjectSpace.each_object Symbol
        end

        def call arg0
          arg0 === @en.next
        end
      end

      Upl::Foreign.register_nondet(:symbol){SymbolIterator.new}

      rv = Upl.query('symbol(Symbol)').to_a
      # dunno why :!== causes trouble. Possibly use of :=== in ObjectIterator?
      true_false = -> sym { [true, false, :true, :false, :'!=='].include? sym }
      rv.map{ _1[:Symbol] }.reject(&true_false).sort.should == ObjectSpace.each_object(Symbol).reject(&true_false).sort
    end

    # This is why you have to be really careful doing relational
    # things in a non-relational language...
    # XD
    describe 'two args' do
      class Special
        def initialize arg = nil
          @arg = arg
        end

        def empty?; !@arg end
      end

      class ObjectIterator
        def initialize
          @en = ObjectSpace.each_object
        end

        def call arg0, arg1
          raise "not determined" if Upl::Variable === arg0
          while !(arg0 === (ne = @en.next)); end
          raise "special oops" if Special === ne && !ne.empty?
          arg1 === ne
        end
      end

      Upl::Foreign.register_nondet(:class_object){ObjectIterator.new}

      it 'single input' do
        q = Upl::Query.new 'class_object(Class,Object)' do |row|
          [row[:Class], row[:Object]]
        end

        q[:Class] = Range

        grp = q.group_by{|(type,obj)| type}
        grp.keys.should == [Range]
        grp[Range].count.should > 1
      end

      it 'several inputs' do
        q = Upl::Query.new 'member(Type, [Class1,Class2]),class_object(Type,Object)' do |row|
          [row[:Type], row[:Object]]
        end

        q.Class1 === Range
        q.Class2 === Symbol

        grp = q.group_by{|(type,obj)| type}
        grp.keys.should == [Range, Symbol]
        grp[Range].count.should > 1
        grp[Symbol].count.should > 1

        # and just to check it does it again
        q.to_a.count.should > 2
      end
    end

    it 'several calls'

    it 'fails to provoke cut on first' do
      q = Upl::Query.new 'class_object(Class,Object)' do |row|
        [row[:Class], row[:Object]]
      end

      q[:Class] === Special

      specials = [Special.new(:not_empty)] + 10.times.map{Special.new}

      binding.pry
      q.to_a
    end

    it 'provoke cut on second or subsequent' do
      q = Upl::Query.new 'class_object(Class,Object)' do |row|
        [row[:Class], row[:Object]]
      end

      q[:Class] === Special

      specials = 10.times.map{Special.new}
      binding.pry
      q.to_a
    end

  end
end
