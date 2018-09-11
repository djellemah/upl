# Upl

A ruby wrapper for SWI-Prolog that goes both ways.

The main idea being that you want to just put in a chunk of prolog, and have the
wrapper give you back your answers in terms of the variable names you specified.
Just like what happens in your common-or-garden prolog REPL. But with pry's
syntax colouring and pretty-printing :-)

Also, do prolog-style queries on objects :-DD

## Tutorial

### Queries

To read rules from a prolog file:
``` ruby
[1] pry(main)> Upl.consult '/home/yours/funky_data.pl'
=> true
```

Query a built-in predicate, with a full expression:
``` ruby
[1] pry(main)> enum = Upl.query 'current_prolog_flag(K,V), member(K,[home,executable,shared_object_extension])'
=> #<Enumerator: ...>
[12] pry(main) enum.to_a
=> [{:K=>home, :V=>/usr/lib64/swipl-7.7.18},
 {:K=>executable, :V=>/usr/local/rvm/rubies/ruby-2.6.0-preview2/bin/ruby},
 {:K=>shared_object_extension, :V=>so}]
```

### Facts
Also we want to be able to construct prolog-queryable facts from ruby objects.
In prolog:

``` prolog
?- assert(person(john,anderson)).
true.

?- person(A,B).
A = john,
B = anderson.

?- assert(person(john,anderson)).
true.

?- person(A,B).
false.
```

And in Upl:

``` ruby
[1] pry(Upl):1> fact = Term.functor :person, :john, :anderson
=> person/2(john,anderson)
[2] pry(Upl):1> Runtime.eval Term.functor :assert, fact
=> true
[3] pry(Upl):1> Array query 'person(A,B)'
=> [{:A=>john, :B=>anderson}]
[4] pry(Upl):1> Runtime.eval Term.functor :retract, fact
=> true
[5] pry(Upl):1> Array query 'person(A,B)'
=> []
```

### Objective Facts

Also, with objects other than symbols. Obviously, this is a rabbit-hole of
Alician proportions. So, here we GOOOoooo...

``` ruby
[1] pry(Upl):1> fact = Term.functor :person, :john, :anderson, (o = Object.new)
=> person/3(john,anderson,#<Object:0x0000563346a08e38 @_upl_atom=439429>)
[2] pry(Upl):1> Runtime.eval Term.functor :assert, fact
=> true
[3] pry(Upl):1> ha, = Array query 'person(A,B,C)'
=> [{:A=>john,
  :B=>anderson,
  :C=>#<Object:0x0000563346a08e38 @_upl_atom=439429>}]
[4] pry(Upl):1> ha[:C].equal? o
=> true
```

Woo. An object disappears into prolog, and comes back out again. Having gained
much wisdom. Hurhur. And at least one extra instance variable.

## Disclaimer

This is in-development code. I use it for some things other than just playing with. It might be useful for you too.

## Naming

Upl? Wat!? Why?

Well. ```swipl``` was taken. ```ripl``` was taken. So maybe in keeping with long tradition: rupl. But that leads to ```pry -I. -rrupl``` which is Not Fun. But upl gives you ```pry -I. -rupl``` So it's kinda like ```ubygems```

Also, Upl rhymes with tuple and/or supple. Depending on your pronunciation :-p

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'upl'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install upl

## Usage

For a REPL say

    pry -rupl

or

    bin/console


## Development

Install SWI-Prolog with both the swipl executable and libswipl.so


And bundler wants me to tell you the following:

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/djellemah/upl.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
