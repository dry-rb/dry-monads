---
title: Try
layout: gem-single
name: dry-monads
---

Rescues a block from an exception. The `Try` monad is useful when you want to wrap some code that can raise exceptions of certain types. A common example is making an HTTP request or querying a database.

```ruby
require 'dry-monads'

module ExceptionalLand
  extend Dry::Monads::Try::Mixin

  res = Try() { 10 / 2 }
  res.value! if res.value?
  # => 5

  res = Try() { 10 / 0 }
  res.exception if res.error?
  # => #<ZeroDivisionError: divided by 0>

  # By default Try catches all exceptions inherited from StandardError.
  # However you can catch only certain exceptions like this
  Try(NoMethodError, NotImplementedError) { 10 / 0 }
  # => raised ZeroDivisionError: divided by 0 exception
end
```

It is better if you pass a list of expected exceptions which you are sure you can process. Catching exceptions of all types is considered bad practice.

The `Try` monad consists of two types: `Value` and `Error`. The first is returned when code did not raise an error and the second is returned when the error was captured.


### `bind`

Works exactly the same way as `Result#bind` does.

```ruby
require 'dry-monads'

module ExceptionalLand
  extend Dry::Monads::Try::Mixin

  Try() { 10 / 2 }.bind { |x| x * 3 }
  # => 15

  Try(ZeroDivisionError) { 10 / 0 }.bind { |x| x * 3 }
  # => Failure(ZeroDivisionError: divided by 0)
end
```

### `fmap`

Allows you to chain blocks that can raise exceptions.

```ruby
Try(NetworkError, DBError) { grap_user_by_making_request }.fmap { |user| user_repo.save(user) }

# Possible outcomes:
# => Value(persisted_user)
# => Error(NetworkError: request timeout)
# => Error(DBError: unique constraint violated)
```

### `value!` and `exception`

Use `value!` for unwrapping a `Success` and `exception` for getting error object from a `Failure`.

### `to_result` and `to_maybe`

`Try`'s `Value` and `Error` can be transformed to `Success` and `Failure` correspondingly by calling `to_result` and to `Some` and `None` by calling `to_maybe`. Keep in mind that by transforming `Try` to `Maybe` you lose the information about an exception so be sure that you've processed the error before doing so.
