def register_test_predicate
  Upl::Foreign.register_semidet :upl_block do |term_t0, term_t1|
    fterm = (Upl::Tree.of_term term_t0)
    p foreign: fterm

    if Symbol === fterm then
      Upl::Extern::PL_unify term_t1, :there.to_term_t
    end
  end

  Array Upl.query "upl_block(hello,A)"
end

=begin
  include UPL
  vars = Variables.new :V
  term = Term :mcall, (o = Object.new), :to_s, vars.V
  def o.to_s; "This is from Ruby, with Love :-D"; end
  Array Runtime.term_vars_query term, vars
  => [{:V=>"This is from Ruby, with Love :-D"}]

  mcall(+Object, +Method, -Result)
=end

def doit
  fact = Upl::Term.functor :person, :john, :anderson, Object.new
  Upl.assertz fact
  vs = Array Upl.query 'person(A,B,C)'
  p vs
  1000.times{Array Upl.query 'current_prolog_flag(K,V)'}
  Upl.retract fact
  Upl::Runtime.call Upl::Term :garbage_collect_atoms
end
