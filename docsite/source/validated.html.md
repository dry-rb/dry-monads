---
title: Validated
layout: gem-single
name: dry-monads
---

Suppose you've got a form to validate. If you are using `Result` combined with `Do` your code might look like this:

```ruby
require 'dry/monads'

class CreateAccount
  include Dry::Monads[:result, :do]

  def call(form)
    name = yield validate_name(form)
    email = yield validate_email(form)
    password = yield validate_password(form)

    user = repo.create_user(
      name: name,
      email: email,
      password: password
    )

    Success(user)
  end

  def validate_name(form)
    # Success(name) or Failure(:invalid_name)
  end

  def validate_email(form)
    # Success(email) or Failure(:invalid_email)
  end

  def validate_password(form)
    # Success(password) or Failure(:invalid_password)
  end
end
```

If any of the validation steps fails the user will see an error. The problem is if `name` is not valid the user won't see errors about invalid `email` and `password`, if any. `Validated` circumvents this particular problem.

`Validated` is actually not a monad but an applicative functor. This means you can't call `bind` on it. Instead, it can accumulate values in combination with `List`:

```ruby
require 'dry/monads'

class CreateAccount
  include Dry::Monads[:list, :result, :validated, :do]

  def call(form)
    name, email, password = yield List::Validated[
      validate_name(form),
      validate_email(form),
      validate_password(form)
    ].traverse.to_result

    user = repo.create_user(
      name: name,
      email: email,
      password: password
    )

    Success(user)
  end

  def validate_name(form)
    # Valid(name) or Invalid(:invalid_name)
  end

  def validate_email(form)
    # Valid(email) or Invalid(:invalid_email)
  end

  def validate_password(form)
    # Valid(password) or Invalid(:invalid_password)
  end
end
```

Here all validations will be processed at once, if any of them fails the result will be converted to a `Failure` wrapping the `List` of errors:

```ruby
create_account.(form)
# => Failure(List[:invalid_name, :invalid_email])
```
