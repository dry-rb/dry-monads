---
title: Do notation
layout: gem-single
name: dry-monads
---

Composing several monadic values can become tedious because you need to pass around unwrapped values in lambdas (aka blocks). Haskell was one of the first languages faced this problem. To work around it Haskell has a special syntax for combining monadic operations called the "do notation". If you're familiar with Scala it has `for`-comprehensions for a similar purpose. It is not possible to implement `do` in Ruby but it is possible to emulate it to some extent, i.e. achieve comparable usefulness.

What `Do` does is passing an unwrapping block to certain methods. The block tries to extract the underlying value from a monadic object and either short-circuits the execution (in case of a failure) or returns the unwrapped value back.

See the following example written using `bind` and `fmap`:

```ruby
require 'dry/monads'

class CreateAccount
  include Dry::Monads[:result]

  def call(params)
    validate(params).bind do |values|
      create_account(values[:account]).bind do |account|
        create_owner(account, values[:owner]).fmap do |owner|
          [account, owner]
        end
      end
    end
  end

  def validate(params)
    # returns Success(values) or Failure(:invalid_data)
  end

  def create_account(account_values)
    # returns Success(account) or Failure(:account_not_created)
  end

  def create_owner(account, owner_values)
    # returns Success(owner) or Failure(:owner_not_created)
  end
end
```

The more monadic steps you need to combine the harder it becomes, not to mention how difficult it can be to refactor code written in such way.

Embrace `Do`:

```ruby
require 'dry/monads'
require 'dry/monads/do'

class CreateAccount
  include Dry::Monads[:result]
  include Dry::Monads::Do.for(:call)

  def call(params)
    values = yield validate(params)
    account = yield create_account(values[:account])
    owner = yield create_owner(account, values[:owner])

    Success([account, owner])
  end

  def validate(params)
    # returns Success(values) or Failure(:invalid_data)
  end

  def create_account(account_values)
    # returns Success(account) or Failure(:account_not_created)
  end

  def create_owner(account, owner_values)
    # returns Success(owner) or Failure(:owner_not_created)
  end
end
```

Both snippets do the same thing yet the second one is a lot easier to deal with. All what `Do` does here is prepending `CreateAccount` with a module which passes a block to `CreateAccount#call`.

#### yield
A little more on `yield`. It will accept a `Result` (remember that's either a Success or Failure object) and **if** the `Result` is a Success object, then yield will unpack it.

For example, in the above `Do` code snippet (repeated below for clarify), if `create_account` returns Success("account created") then the `yield` part will unpack the value of Success and simply return "account created"

```ruby
account = yield create_account(values[:account])
```

It's worth mentioning that if `create_account` returns a Failure then yield won't unpack that but instead short circuit the execution.

That simple.

### Transaction safety

Under the hood, `Do` uses exceptions to halt unsuccessful operations, this can be slower if you are dealing with unsuccessful paths a lot, but usually, this is not an issue. Check out [this article](https://www.morozov.is/2018/05/27/do-notation-ruby.html) for actual benchmarks.

One particular reason to use exceptions is the ability to make code transaction-friendly. In the example above, this piece of code is not atomic:

```ruby
account = yield create_account(values[:account])
owner = yield create_owner(account, values[:owner])

Success[account, owner]
```

What if `create_account` succeeds and `create_owner` fails? This will leave your database in an inconsistent state. Let's wrap it with a transaction block:

```ruby
repo.transaction do
  account = yield create_account(values[:account])
  owner = yield create_owner(account, values[:owner])

  Success[account, owner]
end
```

Since `yield` internally uses exceptions to control the flow, the exception will be detected by the `transaction` call and the whole operation will be rolled back. No more garbage in your database, yay!

### Limitations

`Do` only works with single-value monads, i.e. most of them. At the moment, there is no way to make it work with `List`, though.

### Adding batteries

The `Do::All` module takes one step ahead, it tracks all new methods defined in the class and passes a block to every one of them. However, if you pass a block yourself then it takes precedence. This way, in most cases you can use `Do::All` instead of listing methods with `Do.for(...)`:

```ruby
require 'dry/monads'

class CreateAccount
  # This will include Do::All by default
  include Dry::Monads[:result, :do]

  def call(account_params, owner_params)
    repo.transaction do
      account = yield create_account(account_params)
      owner = yield create_owner(account, owner_params)

      Success[account, owner]
    end
  end

  def create_account(params)
    values = yield validate_account(params)
    account = repo.create_account(values)

    Success(account)
  end

  def create_owner(account, params)
    values = yield validate_owner(params)
    owner = repo.create_owner(account, values)

    Success(owner)
  end

  def validate_account(params)
    # returns Success/Failure
  end

  def validate_owner(params)
    # returns Success/Failure
  end
end
```

Note that `Do::All` will not automatically pass a block to methods inherited from ancestors, such as included modules or a parent class.

### Using `Do` methods in other contexts

You can use methods from the `Do` module directly (starting with 1.3):

```ruby
require 'dry/monads/do'
require 'dry/monads/result'

# some random place in your code
Dry::Monads.Do.() do
  user = Dry::Monads::Do.bind create_user
  account = Dry::Monads::Do.bind create_account(user)

  Dry::Monads::Success[user, account]
end
```

Or you can use `extend`:

```ruby
require 'dry/monads'

class VeryComplexAndUglyCode
  extend Dry::Monads::Do::Mixin
  extend Dry::Monads[:result]

  def self.create_something(result_value)
    call do
      extracted = bind result_value
      processed = bind process(extracted)

      Success(processed)
    end
  end
end
```

`Do::All` also works with class methods:

```ruby
require 'dry/monads'

class SomeClassLevelLogic
  extend Dry::Monads[:result, :do]

  def self.call
    x = yield Success(5)
    y = yield Success(20)

    Success(x * y)
  end
end

SomeClassLevelLogic.() # => Success(100)
```
