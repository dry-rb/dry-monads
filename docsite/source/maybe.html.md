---
title: Maybe
layout: gem-single
name: dry-monads
---

The `Maybe` monad is used when a series of computations could return `nil` at any point.

### `bind`

Applies a block to a monadic value. If the value is `Some` then calls the block passing the unwrapped value as an argument. Returns itself if the value is `None`.

```ruby
extend Dry::Monads[:maybe]

maybe_street = Maybe(user).bind do |u|
  Maybe(u.address).bind do |a|
    Maybe(a.street)
  end
end

# If user with address exists
# => Some("Street Address")
# If user or address is nil
# => None()

# You also can pass a proc to #bind

add_two = -> (x) { Maybe(x + 2) }

Maybe(5).bind(add_two).bind(add_two) # => Some(9)
Maybe(nil).bind(add_two).bind(add_two) # => None()

```

### `fmap`

Similar to `bind` but works with blocks/methods that returns unwrapped values (i.e. not `Maybe` instances).

```ruby
extend Dry::Monads[:maybe]

Maybe(10).fmap { |x| x + 5 }.fmap { |y| y * 2 }
# => Some(30)
```

In 1.x `Maybe#fmap` coerces `nil` values returned from blocks to `None`. This behavior will be changed in 2.0. This will be done because implicit coercion violates the functor laws which in order can lead to a surpising (not in a good sense) behavior. If you expect a block to return `nil`, use `Maybe#maybe` added in 1.3.

### `maybe`

Almost identical to `Maybe#fmap` but maps `nil` to `None`. This is similar to how the `&.` operator works in Ruby but does wrapping:

```ruby
extend Dry::Monads[:maybe]

Maybe(user).maybe(&:address).maybe(&:street)

# If user with address exists
# => Some("Street Address")
# If user or address is nil
# => None()
```

### `value!`

You always can extract the result by calling `value!`. It will raise an error if you call it on `None`. You can use `value_or` for safe unwrapping.

```ruby
extend Dry::Monads[:maybe]

Some(5).fmap(&:succ).value! # => 6

None().fmap(&:succ).value!
# => Dry::Monads::UnwrapError: value! was called on None

```

### `value_or`

Has one argument, unwraps the value in case of `Some` or returns the argument value back in case of `None`. It's a safe and recommended way of extracting values.

```ruby
extend Dry::Monads[:maybe]

add_two = -> (x) { Maybe(x + 2) }

Maybe(5).bind(add_two).value_or(0) # => 7
Maybe(nil).bind(add_two).value_or(0) # => 0

Maybe(nil).bind(add_two).value_or { 0 } # => 0
```

### `or`

The opposite of `bind`.

```ruby
extend Dry::Monads[:maybe]

add_two = -> (x) { Maybe(x + 2) }

Maybe(5).bind(add_two).or(Some(0)) # => Some(7)
Maybe(nil).bind(add_two).or(Some(0)) # => Some(0)

Maybe(nil).bind(add_two).or { Some(0) } # => Some(0)
```

### `and`

Two values can be chained using `.and`:

```ruby
extend Dry::Monads[:maybe]

Some(5).and(Some(10)) { |x, y| x + y } # => Some(15)
Some(5).and(None) { |x, y| x + y }     # => None()
None().and(Some(10)) { |x, y| x + y }  # => None()

Some(5).and(Some(10)) # => Some([5, 10])
Some(5).and(None())   # => None()
```

### `flatten`

To remove one level of nesting:

```ruby
extend Dry::Monads[:maybe]

Some(Some(10)).flatten # => Some(10)
Some(None()).flatten   # => None()
None().flatten         # => None()
```

### `to_result`

Maybe values can be converted to Result objects:

```ruby
extend Dry::Monads[:maybe, :result]

Some(10).to_result # => Success(10)
None().to_result # => Failure()
None().to_result(:error) # => Failure(:error)
None().to_result { :block_value } # => Failure(:block_value)
```
