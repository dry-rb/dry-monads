---
title: Case equality
layout: gem-single
name: dry-monads
---

### Case equality

Monads allow to use default ruby `case` operator for matching result:

```ruby
case value
when Some(1), Some(2) then :one_or_two
when Some(3..5) then :three_to_five
else
  :something_else
end
```

You can use specific `Failure` options too:

```ruby
case value
when Success then [:ok, value.value!]
when Failure(TimeoutError) then [:timeout]
when Failure(ConnectionClosed) then [:net_error]
when Failure then [:generic_error]
else
  raise "Unhandled case"
end
```

#### Nested structures

```ruby
case value
when Success(None()) then :nothing
when Success(Some { |x| x > 10 }) then :something
when Success(Some) then :something_else
when Failure then :error
end
```
