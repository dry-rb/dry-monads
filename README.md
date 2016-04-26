# dry-monads

Monads for Ruby.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dry-monads'
```

And then execute:

```sh
$ bundle
```

Or install it yourself as:

```sh
$ gem install dry-monads
```

## Usage

### Maybe monad

The `Maybe` mondad is used when a series of computations that could return `nil`
at any point.

#### `>>` or `bind`

```
require 'dry/monads'

maybe_user = Dry::Monads::Maybe(user) >> -> (u) {
  Dry::Monads::Maybe(user.address) >> -> (a) {
    Dry::Monads::Maybe(a.street)
  }
}

# If user with address exists
# => Some("Street Address")
# If user or address is nil
# => None()
```

#### `fmap`

```
require 'dry/monads'

Dry::Monads::Maybe(user).fmap(&:address).fmap(&:street)

# If user with address exists
# => Some("Street Address")
# If user or address is nil
# => None()
```

### Either monad

The `Either` mondad is useful to express a series of computations that might
return an error object with additional information.

The `Either` mixin has two type constructors: `Right` and `Left`. The `Right`
can be thought of as "everything went right" and the `Left` is used when
"something has gone wrong".

#### `Either::Mixin`

```
require 'dry/monads'

class EitherCalculator
  include Dry::Monads::Either::Mixin

  attr_accessor :input

  def calculate
    i = input.to_i
    Right(i) >> -> (value) {
      if value > 1
        Right(value + 3)
      else
        Left("value was less than 1")
      end
    } >> -> (value) {
      if value % 2 == 0
        Right(value * 2)
      else
        Left("value was not even")
      end
    }
  end
end

# EitherCalculator instance
c = EitherCalculator.new

# If everything went right
c.input = 3
result = c.calculate
result # => Right(12)
result.value # => 12

# If if failed in the first proc
c.input = 0
result = c.calculate
result # => Left("value was less than 1")
result.value # => "value was less than 1"

# if it failed in the second proc
c.input = 2
result = c.calculate
result # => Left("value was not even")
result.value # => "value was not even"
```

#### `fmap`

An exmple of using `fmap` with `Right` and `Left`.

```
require 'dry/monads'

result = if foo > bar
  Dry::Monads::Right(10)
else
  Dry::Monads::Left("wrong")
end.fmap { |x| x * 2 }

# If everything went right
result # => Right(20)
# If it did not
result # => Left("wrong")
```

#### `or`

An example of using `or` with `Right` and `Left`.

```
Dry::Monads::Right(10).or(Dry::Monads::Right(99)) # => Right(10)
Dry::Monads::Left("error").or(Dry::Monads::Left("new error")) # => Left("new error")
Dry::Monads::Left("error").or { |err| Dry::Monads::Left("new #{err}") } # => Left("new error")
```

#### `to_maybe`

Sometimes it's usefule to turn an 'Either' into a 'Maybe'

```
require 'dry/monads'

result = if foo > bar
  Dry::Monads::Right(10)
else
  Dry::Monads::Left("wrong")
end.to_maybe

# If everything went right
result # => Some(10)
# If it did not
result # => None()
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run
`rake spec` to run the tests. You can also run `bin/console` for an interactive
prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/dry-rb/dry-monads]().
