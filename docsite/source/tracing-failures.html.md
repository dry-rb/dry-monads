---
title: Tracing failures
layout: gem-single
name: dry-monads
---

"Left" values of right-biased monads like `Maybe` and `Result` (as in, `None()` and `Failure()`) ignore blocks passed to `fmap` and `bind`. Because of this, these values travel across the application without any modification. If the place where a `Failure` was constructed is burried somewhere deep in the app or library code it may be pretty hard to find out where exactly the error occurred.

This is a noticable downside compared to "good" old exceptions. To address it, every `Failure(...)` and `None()` value tracks the line where it was created:

```ruby
# create_user.rb
require 'dry/monads'

class CreateUser
  include Dry::Monads[:result]

  def call
    Failure(:no_luck)
  end
end
```

```ruby
require 'create_user'

create_user = CreateUser.new
create_user.()       # => Failure(:no_luck)
create_user.().trace # => .../create_user.rb:8:in `call'
```

Note that the trace stores only one line of the stack so it shouldn't ever be a performance issue.
