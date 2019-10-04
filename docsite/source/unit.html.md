---
title: Unit
layout: gem-single
name: dry-monads
---

Some constructors do not require you to pass a value. As a default they use `Unit`, a special singleton value:

```ruby
extend Dry::Monads[:result]

Success().value! # => Unit
```

`Unit` doesn't have any special properties or methods, it's similar to `nil` except for it is not i.e. `if Unit` passes.

`Unit` is usually excluded from the output:

```ruby
extend Dry::Monads[:result]

# Outputs as "Success()" but technically it's "Success(Unit)"
Success()
```

### Discarding values

When the outcome of an operation is not a caller's concern, call `.discard`, it will map the wrapped value to `Unit`:

```ruby
extend Dry::Monads[:result]

result = create_user # returns Success(#<User...>) or Failure(...)

result.discard # => Maps Success(#<User ...>) to Success() but lefts Failure(...) intact
```
