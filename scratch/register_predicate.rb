def doit
  fact = Upl::Term.functor :person, :john, :anderson, Object.new
  Upl.assertz fact
  vs = Array Upl.query 'person(A,B,C)'
  p vs
  1000.times{Array Upl.query 'current_prolog_flag(K,V)'}
  Upl.retract fact
  Upl::Runtime.call Upl::Term :garbage_collect_atoms
end
