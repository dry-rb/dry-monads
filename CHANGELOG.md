# v0.2.1 2016-11-13

## Added

* Added `Either#tee` that is similar to `Object#tap` but executes the block only for `Right` instances (saverio-kantox)

## Fixed

* `Right(nil).to_maybe` now returns `None` with a warning instead of failing (orisaka)
* `Some#value_or` doesn't require an argument because `None#value_or` doesn't require it either if a block was passed (flash-gordon)

[Compare v0.2.1...v0.2.0](https://github.com/dry-rb/dry-monads/compare/v0.2.1...v0.2.0)

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
