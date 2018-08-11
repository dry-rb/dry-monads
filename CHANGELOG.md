# v1.0.1 2018-08-11

## Fixed

* Fixed behavior of `List<Validated>#traverse` in presence of `Valid` values (flash-gordon + SunnyMagadan)

## Added

* `to_proc` was added to value constructors (flash-gordon)
  ```ruby
  [1, 2, 3].map(&Some) # => [Some(1), Some(2), Some(3)]
  ```

[Compare v1.0.0...v1.0.1](https://github.com/dry-rb/dry-monads/compare/v1.0.0...v1.0.1)

# v1.0.0 2018-06-26

## Added

* `do`-like notation (the idea comes from Haskell of course). This is the biggest and most important addition to the release which greatly increases the ergonomics of using monads in Ruby. Basically, almost everything it does is passing a block to a given method. You call `yield` on monads to extract the values. If any operation fails i.e. no value can be extracted, the whole computation is halted and the failing step becomes a result. With `Do` you don't need to chain monadic values with `fmap/bind` and block, everything can be done on a single level of indentation. Here is a more or less real-life example:

  ```ruby
  class CreateUser
    include Dry::Monads
    include Dry::Monads::Do.for(:call)

    attr_reader :user_repo

    def initialize(:user_repo)
      @user_repo = user_repo
    end

    def call(params)
      json = yield parse_json(params)
      hash = yield validate(json)

      user_repo.transaction do
        user = yield create_user(hash[:user])
        yield create_profile(user, hash[:profile])

        Success(user)
      end
    end

    private

    def parse_json(params)
      Try[JSON::ParserError] {
        JSON.parse(params)
      }.to_result
    end

    def validate(json)
      UserSchema.(json).to_monad
    end

    def create_user(user_data)
      Try[Sequel::Error] { user_repo.create(user_data) }.to_result
    end

    def create_profile(user, profile_data)
      Try[Sequel::Error] {
        user_repo.create_profile(user, profile_data)
      }.to_result
    end
  end
  ```

  In the code above any `yield` can potentially fail and return the failure reason as a result. In other words, `yield None` acts as `return None`. Internally, `Do` uses exceptions, not `return`, this is somewhat slower but allows to detect failed operations in DB-transactions and roll back the changes which far more useful than an unjustifiable speed boost (flash-gordon)

* The `Task` monad based on `Promise` from the [`concurrent-ruby` gem](https://github.com/ruby-concurrency/concurrent-ruby/). `Task` represents an asynchronous computation which _can be_ (doesn't have to!) run on a separated thread. `Promise` already offers a good API and implemented in a safe manner so `dry-monads` just adds a monad-compatible interface for it. Out of the box, `concurrent-ruby` has three types of executors for running blocks: `:io`, `:fast`, `:immediate`, check out [the docs](http://ruby-concurrency.github.io/concurrent-ruby/root/Concurrent.html#executor-class_method) for details. You can provide your own executor if needed (flash-gordon)

  ```ruby
  include Dry::Monads::Task::Mixin

  def call
    name = Task { get_name_via_http }    # runs a request in the background
    email = Task { get_email_via_http }  # runs another one request in the background

    # to_result forces both computations/requests to complete by pausing current thread
    # returns `Result::Success/Result::Failure`
    name.bind { |n| email.fmap { |e| create(e, n) } }.to_result
  end
  ```

  `Task` works perfectly with `Do`

  ```ruby
  include Dry::Monads::Do.for(:call)

  def call
    name, email = yield Task { get_name_via_http }, Task { get_email_via_http }
    Success(create(e, n))
  end
  ```

* `Lazy` is a copy of `Task` that isn't run until you ask for the value _for the first time_. It is guaranteed the evaluation is run at most once as opposed to lazy assignment `||=` which isn't synchronized. `Lazy` is run on the same thread asking for the value (flash-gordon)

* Automatic type inference with `.typed` for lists was deprecated. Instead, typed list builders were added

  ```ruby
  list = List::Task[Task { get_name }, Task { get_email }]
  list.traverse # => Task(List['John', 'john@doe.org'])
  ```

  The code above runs two tasks in parallel and automatically combines their results with `traverse` (flash-gordon)

* `Try` got a new call syntax supported in Ruby 2.5+

  ```ruby
    Try[ArgumentError, TypeError] { unsafe_operation }
  ```

  Prior to 2.5, it wasn't possible to pass a block to `[]`.

* The `Validated` “monad” that represents a result of a validation. Suppose, you want to collect all the errors and return them at once. You can't have it with `Result` because when you `traverse` a `List` of `Result`s it returns the first value and this is the correct behavior from the theoretical point of view. `Validated`, in fact, doesn't have a monad instance but provides a useful variant of applicative which concatenates the errors.

  ```ruby
    include Dry::Monads
    include Dry::Monads::Do.for(:call)

    def call(input)
      name, email = yield [
        validate_name(input[:name]),
        validate_email(input[:email])
      ]

      Success(create(name, email))
    end

    # can return
    # * Success(User(...))
    # * Invalid(List[:invalid_name])
    # * Invalid(List[:invalid_email])
    # * Invalid(List[:invalid_name, :invalid_email])
  ```

  In the example above an array of `Validated` values is implicitly coerced to `List::Validated`. It's supported because it's useful but don't forget it's all about types so don't mix different types of monads in a single array, the consequences are unclear. You always can be explicit with `List::Validated[validate_name(...), ...]`, choose what you like (flash-gordon).

* `Failure`, `None`, and `Invalid` values now store the line where they were created. One of the biggest downsides of dealing with monadic code is lack of backtraces. If you have a long list of computations and one of them fails how do you know where did it actually happen? Say, you've got `None` and this tells you nothing about _what variable_ was assigned to `None`. It makes sense to use `Result` instead of `Maybe` and use distinct errors everywhere but it doesn't always look good and forces you to think more. TLDR; call `.trace` to get the line where a fail-case was constructed

  ```ruby
  Failure(:invalid_name).trace # => app/operations/create_user.rb:43
  ```

* `Dry::Monads::Unit` which can be used as a replacement for `Success(nil)` and in similar situations when you have side effects yet doesn't return anything meaningful as a result. There's also the `.discard` method for mapping any successful result (i.e. `Success(?)`, `Some(?)`, `Value(?)`, etc) to `Unit`.

  ```ruby
    # we're making an HTTP request but "forget" any successful result,
    # we only care if the task was complete without an error
    Task { do_http_request }.discard
    # ... wait for the task to finish ...
    # => Task(valut=Unit)
  ```

## Deprecations

* `Either`, the former name of `Result`, is now deprecated

## BREAKING CHANGES

* `Either#value` and `Maybe#value` were both droped, use `value_or` or `value!` when you :100: sure it's safe
* `require 'dry/monads'` doesn't load all monads anymore, use `require 'dry/monads/all'` instead or cherry pick them with `require 'dry/monads/maybe'` etc (timriley)

[Compare v0.4.0...v1.0.0](https://github.com/dry-rb/dry-monads/compare/v0.4.0...v1.0.0)

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
