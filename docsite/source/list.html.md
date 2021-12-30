---
title: List
layout: gem-single
name: dry-monads
---

### `bind`

Lifts a block/proc and runs it against each member of the list. The block must return a value coercible to a list. As in other monads if no block given the first argument will be treated as callable and used instead.

```ruby
require 'dry/monads/list'

M = Dry::Monads

M::List[1, 2].bind { |x| [x + 1] } # => List[2, 3]
M::List[1, 2].bind(-> x { [x, x + 1] }) # => List[1, 2, 2, 3]

M::List[1, nil].bind { |x| [x + 1] } # => error
```

### `collect`

Works differently than `Enumerable#collect`: the block must return `Maybe` types, `Some` values are retained and `None` is discarded. As in other monads if no block given the first argument will be treated as callable and used instead.

```ruby
require 'dry/monads/list'

M = Dry::Monads

n = 20
M::List[10, 5, 0].collect do |divisor|
  if divisor.zero?
    M::None()
  else
    M::Some(n / divisor)
  end
end
# => List[2, 4]

M::List[M::Some(1), M::None(), M::Some(2), M::None(), M::Some(3)].collect # => List[1, 2, 3]

leap_year = proc do |year|
  if year % 400 == 0
    M::Some(year)
  elsif year % 100 == 0
    M::None()
  elsif year % 4 == 0
    M::Some(year)
  else
    M::None()
  end
end

M::List[2020, 2021, 2022, 2023, 2024].collect(leap_year) # => List[2020, 2024]
```

### `fmap`

Maps a block over the list. Acts as `Array#map`. As in other monads, if no block given the first argument will be treated as callable and used instead.

```ruby
require 'dry/monads/list'

M = Dry::Monads

M::List[1, 2].fmap { |x| x + 1 } # => List[2, 3]
```

### `value`

You always can unwrap the result by calling `value`.

```ruby
require 'dry/monads/list'

M = Dry::Monads

M::List[1, 2].value # => [1, 2]
```

### Concatenation

```ruby
require 'dry/monads/list'

M = Dry::Monads

M::List[1, 2] + M::List[3, 4] # => List[1, 2, 3, 4]
```

### `head` and `tail`

`head` returns the first element wrapped with a `Maybe`.

```ruby
require 'dry/monads/list'

M = Dry::Monads

M::List[1, 2, 3, 4].head # => Some(1)
M::List[1, 2, 3, 4].tail # => List[2, 3, 4]
```

### `traverse`

Traverses the list with a block (or without it). This method "flips" List structure with the given monad (obtained from the type).

**Note that traversing requires the list to be typed.**

```ruby
require 'dry/monads/list'

M = Dry::Monads

M::List[M::Success(1), M::Success(2)].typed(M::Result).traverse # => Success(List[1, 2])
M::List[M::Maybe(1), M::Maybe(nil), M::Maybe(3)].typed(M::Maybe).traverse # => None

# also, you can use fmap with #traverse

M::List[1, 2].fmap { |x| M::Success(x) }.typed(M::Result).traverse # => Success(List[1, 2])
M::List[1, nil, 3].fmap { |x| M::Maybe(x) }.typed(M::Maybe).traverse # => None
```
