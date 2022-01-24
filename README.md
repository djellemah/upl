![rspecs](https://github.com/djellemah/upl/actions/workflows/build.yml/badge.svg)

# Upl

Use SWI-Prolog from ruby.

prolog statements can be specified as strings or as a ruby DSL.

Define foreign predicates in ruby, so prolog can call back into ruby code.

Assert facts containing ruby objects, so prolog can query ruby data by calling ruby methods.

## versions

Works on ruby-2.7, ruby-3.0 and ruby-3.1

and swipl-8.1.29 to swipl-8.5.3

## Tutorial

The query api always returns an ```Enumerable``` of all values which satisfy the query.

### Queries

Query a built-in predicate, with a full expression:

``` ruby
[1] pry(main)> q = Upl::Query.new <<~prolog
  member(K,[home,executable,shared_object_extension]),
  current_prolog_flag(K,V)
prolog
=> #<Upl::Query...>
[2] pry(main) q.to_a
=> [{:K=>:executable, :V=>:upl},
    {:K=>:home, :V=>:"/usr/lib64/swipl"},
    {:K=>:shared_object_extension, :V=>:so}]
```

To read rules from a prolog file:

``` ruby
[1] pry(main)> Upl.consult '/home/yours/funky_data.pl'
=> true
```

### Facts
Also we want to be able to construct prolog-queryable facts from ruby objects.
In prolog:

``` prolog
?- assertz(person(john,anderson)).
true.

?- person(A,B).
A = john,
B = anderson.

?- retract(person(john,anderson)).
true.

?- person(A,B).
false.
```

And in Upl:

``` ruby
[1] pry(main)> fact = Upl::Term :person, :john, :anderson
=> person/2(john,anderson)
[2] pry(main)> Upl.assertz fact
=> true
[3] pry(main)> Array Upl.query 'person(A,B)'
=> [{:A=>john, :B=>anderson}]
[4] pry(main)> Upl.retract fact
=> true
[5] pry(main)> Array Upl.query 'person(A,B)'
=> []
```

### Objective Facts

Also, with objects other than symbols. Obviously, this is a rabbit-hole of
Alician proportions. So, here we GOOOoooo...

``` ruby
[1] pry(main)> fact = Upl::Term :person, :john, :anderson, (o = Object.new)
=> person/3(john,anderson,#<Object:0x0000563346a08e38 @_upl_atom=439429>)
[2] pry(main)> Upl.assertz fact
=> true
[3] pry(main)> Upl::Query.new('person(A,B,C)').first[:C]
=> #<Object:0x0000563346a08e38 @_upl_atom=439429>}]
```

Woo. An object disappears into prolog, and comes back out again. Having gained
much wisdom. Hurhur. And at least one extra instance variable.

And now, the pièce de résistance - using an object as an input term:

``` ruby
fact =  Upl::Term :person, :james, :madison, (o = Object.new)
Upl.assertz fact

fact2 = Upl::Term :person, :thomas, :paine, (thing2 = Object.new)
Upl.assertz fact2

# Note that both facts are in the result and the values for C are different
q = Upl::Query.new 'person(A,B,C)'
q.to_a
=>[
 {:A=>james,  :B=>madison, :C=>#<Object:0x0000563f56e35580 @_upl_atom=439429>},
 {:A=>thomas, :B=>paine,   :C=>#<Object:0x0000563f56d2b5b8 @_upl_atom=439813>}
]

# Unify C with thing2
q = Upl::Query.new 'person(A,B,C)'
q.C = thing2

# ... and we get the correct result
# Note that the first fact is not in the result.
q.first
=> [{:A=>thomas, :B=>paine, :C=>#<Object:0x0000563f56d2b5b8 @_upl_atom=439813>}]
```

### Ruby Methods
You can call methods on ruby objects from prolog using the ```mcall(+Object, +Method, -Result)``` predicate:

``` ruby
def (obj = Object.new).voicemail
  "Hey. For your logs."
end

q = Upl::Query.new "mcall(O,voicemail,St),string_codes(St,Co)"
q.O = obj
q.to_a
=> [{:O=>#<Object:0x00005610453b0528 @_upl_atom=495109>,
  :St=>"Hey. For your logs.",
  :Co=>[72, 101, 121, 46, 32, 70, 111, 114, 32, 121, 111, 117, 114, 32, 108, 111, 103, 115, 46]}]
```

### Ruby Predicates

You can define predicates in ruby:

``` ruby
Upl::Foreign.register_semidet :special_concat do |arg0, arg1|
  arg1 === "#{arg0}-special"
end

Upl::Query.new('special_concat(hello, A)').to_a
=> [{:A=>"hello-special"}]
```

Some notes:

* ```===``` means unify

* return value from the register_semidet block will be treated as a ruby
  truthy/falsy value and converted to a prolog true/false, that is as
  success/failure. So you have to be careful here because, for example, returning nil
  would be interpreted by prolog to mean failure, and you will get no results. Or conversely: returning true for a series of unifications where only the last succeeded would lead to incorrect results.

So you now you can define a query in prolog that searches a ruby object graph.

## Limitations

Although this is in-development code, I do use it for real work. For example, driving an address DCG on 50,000 addresses. Memory usage was stable.

It might be useful for you too.

### Specifically

You cannot talk to swipl from a Thread other than ```Thread::main```. See https://www.swi-prolog.org/pldoc/man?section=foreignthread

I've used it to drive an address DCG on 50,000 addresses. Memory usage was stable.

ruby has a GC. swipl has a GC. At some point they will disagree. I haven't reached that point yet.

UTF8-passthrough is not implemented, but there's a good chance you'll get what you want with the help of ```String#force_encoding('UTF-8')```.

There is not yet a way to register nondet predicates in ruby.

## Naming

```Upl```? Wat!? Why?

Well. [```swipl```](https://github.com/meschbach/gem-swipl) was taken for the ```swipl``` gem which does some of what this does. ```ripl``` was taken. So maybe in keeping with long tradition: ```rupl```.

But that leads to ```pry -I. -rrupl``` which is Not Fun.

But ```upl``` gives you ```pry -I. -rupl``` So it's kinda like ```ubygems``` used to be.

Also, ```Upl``` rhymes with tuple and/or supple. Depending on your pronunciation :-p

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
