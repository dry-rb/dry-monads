---
title: Pattern matching
layout: gem-single
name: dry-monads
---

Ruby 2.7 introduces pattern matching, it is nicely supported by dry-monads 1.3+.

### Matching Result values

```ruby
# presumably you do it in a class with `include Dry::Monads[:result]`

case value
in Success(Integer => x)
  # x is bound to an integer
in Success[:created, user]
  # user is bound to the second member
in Success(Date | Time)
  # date or time object
in Success[1, *]
  # any array starting with 1
in Success(String => s) if s.size < 100
  # only if `s` is short enough
in Success(counter: Integer)
  # matches Success(counter: 50)
  # doesn't match Success(counter: 50, extra: 50)
in Success(user: User, account: Account => user_account)
  # matches Success(user: User.new(...), account: Account.new(...), else: ...)
  # user_account is bound to the value of the `:account` key
in Success()
  # corresponds to Success(Unit)
in Success(user:, **rest)
  # matches Success(user: User.new, other_key: "value")
in Success(_)
  # general success
in Failure[:user_not_found]
  # matches Failure([:user_not_found]) or Failure[:user_not_found]
in Failure[error_code, *payload]
  # ...
end
```

In the snippet above, the patterns will be tried sequentially. If `value` doesn't match any pattern, an error will be thrown.

### Matching Maybe

```ruby
case value
in Some(Integer => x) if x > 0
  # x is a positive integer
in Some(Float | String)
  # ...
in None
  # ...
end
```

### Matching List

```ruby
case value
in List[Integer]
  # any list of size 1 with an integer
in List[1, 2, 3, *]
  # list with size >= 3 starting with 1, 2, 3
in List[]
  # empty list
end
```

### Matching array values

dry-monads treats all wrapped array values as tuples rather than lists.
For example, this will not work:

```ruby
Success([1, 2, 3]) in Success(numbers) # => no match!
```

But this will:

```ruby
Success([1, 2, 3]) in Success(one, two, three)
```

And this will too:

```ruby
Success([1, 2, 3]) in Success[1, 2 ,3]
```

To capture an array value, use `*`:

```ruby
Success([1, 2, 3]) in Success(*numbers)
```

At least for `Failure` values, people use tuples more often; this is why dry-monads treats _all_ arrays as tuples. We could make `Success`/`Failure` behaviors different, but this would be even more unexpected.
