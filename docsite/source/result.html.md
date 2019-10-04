---
title: Result
layout: gem-single
name: dry-monads
---

The `Result` monad is useful to express a series of computations that might
return an error object with additional information.

The `Result` mixin has two type constructors: `Success` and `Failure`. The `Success`
can be thought of as "everything went success" and the `Failure` is used when
"something has gone wrong".

### `Result::Mixin`

```ruby
require 'dry-monads'

class ResultCalculator
  include Dry::Monads::Result::Mixin

  attr_accessor :input

  def calculate
    i = Integer(input)

    Success(i).bind do |value|
      if value > 1
        Success(value + 3)
      else
        Failure("value was less than 1")
      end
    end.bind do |value|
      if value % 2 == 0
        Success(value * 2)
      else
        Failure("value was not even")
      end
    end
  end
end

# ResultCalculator instance
c = ResultCalculator.new

# If everything went success
c.input = 3
result = c.calculate
result # => Success(12)

# If it failed in the first block
c.input = 0
result = c.calculate
result # => Failure("value was less than 1")

# if it failed in the second block
c.input = 2
result = c.calculate
result # => Failure("value was not even")
```

### `bind`

Use `bind` for composing several possibly-failing operations:

```ruby
require 'dry-monads'

M = Dry::Monads

class AssociateUser
  def call(user_id:, address_id:)
    find_user(user_id).bind do |user|
      find_address(address_id).fmap do |address|
        user.update(address_id: address.id)
      end
    end
  end

  private

  def find_user(id)
    user = User.find_by(id: id)

    if user
      Success(user)
    else
      Failure(:user_not_found)
    end
  end

  def find_address(id)
    address = Address.find_by(id: id)

    if address
      Success(address)
    else
      Failure(:address_not_found)
    end
  end
end

AssociateUser.new.(user_id: 1, address_id: 2)
```

### `fmap`

An example of using `fmap` with `Success` and `Failure`.

```ruby
require 'dry-monads'

M = Dry::Monads

result = if foo > bar
  M.Success(10)
else
  M.Failure("wrong")
end.fmap { |x| x * 2 }

# If everything went success
result # => Success(20)
# If it did not
result # => Failure("wrong")

# #fmap accepts a proc, just like #bind

upcase = :upcase.to_proc

M.Success('hello').fmap(upcase) # => Success("HELLO")
```

### `value_or`

`value_or` is a safe and recommended way of extracting values.

```ruby
M = Dry::Monads

M.Success(10).value_or(0) # => 10
M.Failure('Error').value_or(0) # => 0
```

### `value!`

If you're 100% sure you're dealing with a `Success` case you might use `value!` for extracting the value without providing a default. Beware, this will raise an exception if you call it on `Failure`.

```ruby
M = Dry::Monads

M.Success(10).value! # => 10

M.Failure('Error').value!
# => Dry::Monads::UnwrapError: value! was called on Failure
```

### `or`

An example of using `or` with `Success` and `Failure`.

```ruby
M = Dry::Monads

M.Success(10).or(M.Success(99)) # => Success(10)
M.Failure("error").or(M.Failure("new error")) # => Failure("new error")
M.Failure("error").or { |err| M.Failure("new #{err}") } # => Failure("new error")
```

### `failure`

Use `failure` for unwrapping the value from a `Failure` instance.

```ruby
M = Dry::Monads

M.Failure('Error').failure # => "Error"
```

### `to_maybe`

Sometimes it's useful to turn a `Result` into a `Maybe`.

```ruby
require 'dry-monads'

result = if foo > bar
  Dry::Monads.Success(10)
else
  Dry::Monads.Failure("wrong")
end.to_maybe

# If everything went success
result # => Some(10)
# If it did not
result # => None()
```

### `failure?` and `success?`

You can explicitly check the type by calling `failure?` or `success?` on a monadic value.
