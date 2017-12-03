# v0.4.0 2017-11-11

## Changed

* The `Either` monad was renamed to `Result` which sounds less nerdy but better reflects the purpose of the type. `Either::Right` became `Result::Success` and `Either::Left` became `Result::Failure`. This change is backward-compatible overall but you will see the new names when using old `Left` and `Right` methods (citizen428)
* Consequently, `Try::Success` and `Try::Failure` were renamed to `Try::Value` and `Try::Error` (flash-gordon)

## Added

* `Try#or`, works as `Result#or` (flash-gordon)
* `Maybe#success?` and `Maybe#failure?` (aliases for `#some?` and `#none?`) (flash-gordon)
* `Either#flip` inverts a `Result` value  (flash-gordon)
* `List#map` called without a block returns an `Enumerator` object (flash-gordon)
* Right-biased monads (`Maybe`, `Result`, and `Try`) now implement the `===` operator which is used for equality checks in the `case` statement (flash-gordon)
  ```ruby
    case value
    when Some(1..100)       then :ok
    when Some { |x| x < 0 } then :negative
    when Some(Integer)      then :invalid
    else raise TypeError
    end
  ```

## Deprecated

* Direct accessing `value` on right-biased monads has been deprecated, use the `value!` method instead. `value!` will raise an exception if it is called on a Failure/None/Error instance (flash-gordon)

[Compare v0.3.1...v0.4.0](https://github.com/dry-rb/dry-monads/compare/v0.3.1...v0.4.0)

# v0.3.1 2017-03-18

## Fixed

* Fixed unexpected coercing to `Hash` on `.bind` call (flash-gordon)

[Compare v0.3.0...v0.3.1](https://github.com/dry-rb/dry-monads/compare/v0.3.0...v0.3.1)

# v0.3.0 2017-03-16

## Added
* Added `Either#either` that accepts two callbacks, runs the first if it is `Right` and the second otherwise (nkondratyev)
* Added `#fmap2` and `#fmap3` for mapping over nested structures like `List Either` and `Either Some` (flash-gordon)
* Added `Try#value_or` (dsounded)
* Added the `List` monad which acts as an immutable `Array` and plays nice with other monads. A common example is a list of `Either`s (flash-gordon)
* `#bind` made to work with keyword arguments as extra parameters to the block (flash-gordon)
* Added `List#traverse` that "flips" the list with an embedded monad (flash-gordon + damncabbage)
* Added `#tee` for all right-biased monads (flash-gordon)

[Compare v0.2.1...v0.3.0](https://github.com/dry-rb/dry-monads/compare/v0.2.1...v0.3.0)

# v0.2.1 2016-11-13

## Added

* Added `Either#tee` that is similar to `Object#tap` but executes the block only for `Right` instances (saverio-kantox)

## Fixed

* `Right(nil).to_maybe` now returns `None` with a warning instead of failing (orisaka)
* `Some#value_or` doesn't require an argument because `None#value_or` doesn't require it either if a block was passed (flash-gordon)

[Compare v0.2.0...v0.2.1](https://github.com/dry-rb/dry-monads/compare/v0.2.0...v0.2.1)

# v0.2.0 2016-09-18

## Added

* Added `Maybe#to_json` as an opt-in extension for serialization to JSON (rocknruby)
* Added `Maybe#value_or` which returns you the underlying value with a fallback in a single method call (dsounded)

[Compare v0.1.1...v0.2.0](https://github.com/dry-rb/dry-monads/compare/v0.1.1...v0.2.0)

# v0.1.1 2016-08-25

## Fixed

* Added explicit requires of `dry-equalizer`. This allows to safely load only specific monads (artofhuman)

[Compare v0.1.0...v0.1.1](https://github.com/dry-rb/dry-monads/compare/v0.1.0...v0.1.1)

# v0.1.0 2016-08-23

## Added

* Support for passing extra arguments to the block in `.bind` and `.fmap` (flash-gordon)

## Changed

* Dropped MRI 2.0 support (flash-gordon)

[Compare v0.0.2...v0.1.0](https://github.com/dry-rb/dry-monads/compare/v0.0.2...v0.1.0)

# v0.0.2 2016-06-29

## Added

* Added `Either#to_either` so that you can rely on duck-typing when you work with different types of monads (timriley)
* Added `Maybe#to_maybe` for consistency with `#to_either` (flash-gordon)

[Compare v0.0.1...v0.0.2](https://github.com/dry-rb/dry-monads/compare/v0.0.1...v0.0.2)

# v0.0.1 2016-05-02

Initial release containing `Either`, `Maybe`, and `Try` monads.
