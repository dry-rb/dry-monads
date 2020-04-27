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

### `bind`

Use `bind` for composing several possibly-failing operations:

```ruby
require 'dry/monads'

class AssociateUser
  include Dry::Monads[:result]

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
extend Dry::Monads[:result]

result = if foo > bar
  Success(10)
else
  Failure("wrong")
end.fmap { |x| x * 2 }

# If everything went success
result # => Success(20)
# If it did not
result # => Failure("wrong")

# #fmap accepts a proc, just like #bind

upcase = :upcase.to_proc

Success('hello').fmap(upcase) # => Success("HELLO")
```

### `value_or`

`value_or` is a safe and recommended way of extracting values.

```ruby
extend Dry::Monads[:result]

Success(10).value_or(0) # => 10
Failure('Error').value_or(0) # => 0
```

### `value!`

If you're 100% sure you're dealing with a `Success` case you might use `value!` for extracting the value without providing a default. Beware, this will raise an exception if you call it on `Failure`.

```ruby
extend Dry::Monads[:result]

Success(10).value! # => 10
Failure('Error').value!
# => Dry::Monads::UnwrapError: value! was called on Failure
```

### `value_or_raise!`

Use `value_or_raise!` for extracting values or raising the inner error of a Failure in case there is one.

```ruby
extend Dry::Monads[:result]

Sucess({}).value_or_raise! # => {}
Failure(StandardError.new).value_or_raise! # => Will raise StandardError
```

### `or`

An example of using `or` with `Success` and `Failure`.

```ruby
extend Dry::Monads[:result]

Success(10).or(Success(99)) # => Success(10)
Failure("error").or(Failure("new error")) # => Failure("new error")
Failure("error").or { |err| Failure("new #{err}") } # => Failure("new error")
```

### `failure`

Use `failure` for unwrapping the value from a `Failure` instance.

```ruby
extend Dry::Monads[:result]

Failure('Error').failure # => "Error"
```

### `to_maybe`

Sometimes it's useful to turn a `Result` into a `Maybe`.

```ruby
extend Dry::Monads[:result, :maybe]

result = if foo > bar
  Success(10)
else
  Failure("wrong")
end.to_maybe

# If everything went success
result # => Some(10)
# If it did not
result # => None()
```

### `failure?` and `success?`

You can explicitly check the type by calling `failure?` or `success?` on a monadic value.

### `either`

`either` maps a `Result` to some type by taking two callables, for `Success` and `Failure` cases respectively:

```ruby
Success(1).either(-> x { x + 1 }, -> x { x + 2 }) # => 2
Failure(1).either(-> x { x + 1 }, -> x { x + 2 }) # => 3
```


### Adding constraints to `Failure` values.
You can add type constraints to values passed to `Failure`. This will raise an exception if value doesn't meet the constraints:

```ruby
require 'dry-types'

module Types
  include Dry.Types()
end

class Operation
  Error = Types.Instance(RangeError)
  include Dry::Monads::Result(Error)

  def call(value)
    case value
    when 0..1
      Success(:success)
    when -Float::INFINITY..0, 1..Float::INFINITY
      Failure(RangeError.new('Error'))
    else
      Failure(TypeError.new('Type error'))
    end
  end
end

Operation.new.call(0.5) # => Success(:success)
Operation.new.call(5) # => Failure(#<RangeError: Error>)
Operation.new.call("5") # => Dry::Monads::InvalidFailureTypeError: Cannot create Failure from #<TypeError: Type error>, it doesn't meet the constraints
```
