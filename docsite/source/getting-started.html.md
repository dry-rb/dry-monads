---
title: Getting started
layout: gem-single
name: dry-monads
---

### Installation

Add this line to your Gemfile

```ruby
gem 'dry-monads'
```

Then run

```
$ bundle
```

### Usage

Every monad has corresponding value constructors. For example, the `Maybe` monad has two of them: `Some(...)` and `None()`. It also has the `Maybe(...)` method. All three methods start with a capital letter similarly to built-in Ruby methods like `Kernel#Array(...)` and `Kernel#Hash(...)`. Value constructors are not available globally, you need to add them with a mixin.

To add the `Maybe` constructors add `Dry::Monads[:maybe]` to your class:

```ruby
require 'dry/monads'

class CreateUser
  # this line loads the Maybe monad and adds
  # Some(...), None(), and Maybe(...) to CreateUser
  include Dry::Monads[:maybe]

  def call(params)
    # ...
    if valid?(params)
      Some(create_user(params))
    else
      None()
    end
  end
end
```

Example in the docs may use `extend Dry::Monads[...]` for brevity but you normally want to use `include` in production code.

### Including multiple monads

```ruby
require 'dry/monads'

class CreateUser
  # Adds Maybe and Result. The order doesn't matter
  include Dry::Monads[:maybe, :result]
end
```

### Using with do notation

A very common case is using the [Result](docs::result) monad with [do notation](docs::do-notation):

```ruby
require 'dry/monads'

class ResultCalculator
  include Dry::Monads[:result, :do]

  def calculate(input)
    value = Integer(input)

    value = yield add_3(value)
    value = yield mult_2(value)

    Success(value)
  end

  def add_3(value)
    if value > 1
      Success(value + 3)
    else
      Failure("value was less than 1")
    end
  end

  def mult_2(value)
    if value % 2 == 0
      Success(value * 2)
    else
      Failure("value was not even")
    end
  end
end


c = ResultCalculator.new
c.calculate(3) # => Success(12)
c.calculate(0) # => Failure("value was less than 1")
c.calculate(2) # => Failure("value was not even")
```

### Constructing array values

Some constructors have shortcuts for wrapping arrays:

```ruby
require 'dry/monads'

class CreateUser
  include Dry::Monads[:result]

  def call(params)
    # ...
    # Same as Failure([:user_exists, params: params])
    Failure[:user_exists, params: params]
  end
end
```

### Interaction between monads and constructors availability

Some values can be converted to others or they can have methods that use other monads. By default, dry-monads doesn't load all monads so you may have troubles like this:

```ruby
extend Dry::Monads[:result]

Success(:foo).to_maybe # RuntimeError: Load Maybe first with require 'dry/monads/maybe'
```

To work around you may either load `dry/monads/maybe` add `maybe` to the mixin:

```ruby
extend Dry::Monads[:result, :maybe]

Success(:foo).to_maybe # => Some(:foo)
```

For the same reason `Dry::Monads.Some(...)`, `Dry::Monads.Success(...)`, and some other constructors are not available until you explicitly load the monads with `require 'dry/monads/%{monad_name}'`.

### Loading everything

Just `require 'dry/monads/all'`
