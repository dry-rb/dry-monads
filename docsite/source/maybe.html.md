---
title: Maybe
layout: gem-single
name: dry-monads
---

The `Maybe` monad is used when a series of computations could return `nil` at any point.

### `bind`

Applies a block to a monadic value. If the value is `Some` then calls the block passing the unwrapped value as an argument. Returns itself if the value is `None`.

```ruby
require 'dry-monads'

M = Dry::Monads

maybe_user = M.Maybe(user).bind do |u|
  M.Maybe(u.address).bind do |a|
    M.Maybe(a.street)
  end
end

# If user with address exists
# => Some("Street Address")
# If user or address is nil
# => None()

# You also can pass a proc to #bind

add_two = -> (x) { M.Maybe(x + 2) }

M.Maybe(5).bind(add_two).bind(add_two) # => Some(9)
M.Maybe(nil).bind(add_two).bind(add_two) # => None()

```

### `fmap`

Similar to `bind` but works with blocks/methods that returns unwrapped values (i.e. not `Maybe` instances).

```ruby
require 'dry-monads'

Dry::Monads::Maybe(user).fmap(&:address).fmap(&:street)

# If user with address exists
# => Some("Street Address")
# If user or address is nil
# => None()
```


### `value!`

You always can extract the result by calling `value!`. It will raise an error if you call it on `None`. You can use `value_or` for safe unwrapping.

```ruby
require 'dry-monads'

Dry::Monads::Some(5).fmap(&:succ).value! # => 6

Dry::Monads::None().fmap(&:succ).value!
# => Dry::Monads::UnwrapError: value! was called on None

```


### `value_or`

Has one argument, unwraps the value in case of `Some` or returns the argument value back in case of `None`. It's a safe and recommended way of extracting values.

```ruby
require 'dry-monads'

M = Dry::Monads

add_two = -> (x) { M.Maybe(x + 2) }

M.Maybe(5).bind(add_two).value_or(0) # => 7
M.Maybe(nil).bind(add_two).value_or(0) # => 0

M.Maybe(nil).bind(add_two).value_or { 0 } # => 0
```

### `or`

The opposite of `bind`.

```ruby
require 'dry-monads'

M = Dry::Monads

add_two = -> (x) { M.Maybe(x + 2) }

M.Maybe(5).bind(add_two).or(M.Some(0)) # => Some(7)
M.Maybe(nil).bind(add_two).or(M.Some(0)) # => Some(0)

M.Maybe(nil).bind(add_two).or { M.Some(0) } # => Some(0)
```
