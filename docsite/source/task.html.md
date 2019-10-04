---
title: Task
layout: gem-single
name: dry-monads
---

`Task` represents an asynchronous computation. It is similar to the `IO` type in a sense it can be used to wrap side-effectful actions. `Task`s are usually run on a thread pool but also can be executed immediately on the current thread. Internally, `Task` uses `Promise` from the [`concurrent-ruby`](https://github.com/ruby-concurrency/concurrent-ruby) gem, basically it's a thin wrapper with a monadic interface which makes it easily composable with other monads.

### `Task::Mixin`

Basic usage.

```ruby
require 'dry/monads'

class PullUsersWithPosts
  include Dry::Monads[:task]

  def call
    # Start two tasks running concurrently
    users = Task { fetch_users }
    posts = Task { fetch_posts }

    # Combine two tasks
    users.bind { |us| posts.fmap { |ps| [us, ps] } }
  end

  def fetch_users
    sleep 3
    [{ id: 1, name: 'John' }, { id: 2, name: 'Jane' }]
  end

  def fetch_posts
    sleep 2
    [
      { id: 1, user_id: 1, name: 'Hello from John' },
      { id: 2, user_id: 2, name: 'Hello from Jane' },
    ]
  end
end

# PullUsersWithPosts instance
pull = PullUsersWithPosts.new

# Spin up two tasks
task = pull.call

task.fmap do |users, posts|
  puts "Users: #{ users.inspect }"
  puts "Posts: #{ posts.inspect }"
end

puts "----" # this will be printed before the lines above
```

### Executors

Tasks are performed by executors, there are three executors predefined by `concurrent-ruby` identified by symbols:

- `:fast` – for fast asynchronous tasks, uses a thread pool
- `:io` – for long IO-bound tasks, uses a thread pool, different from `:fast`
- `:immediate` – runs tasks immediately, on the current thread. Can be used in tests or for other purposes

You can create your own executors, check out the [docs](http://ruby-concurrency.github.io/concurrent-ruby/master/Concurrent.html) for more on this.

The following examples use the Ruby 2.5+ syntax which allows passing a block to `.[]`.

```ruby
Task[:io] { do_http_request }

Task[:fast] { cpu_intensive_computation }

Task[:immediate] { unsafe_io_operation }

# You can pass an executor object
Task[my_executor] { ... }
```

### Exception handling

All exceptions happening in `Task` are captured, even if you're using the `:immediate` executor, they won't be re-raised.

```ruby
io_fail = Task[:io] { 1/0 }
io_fail # => Task(error=#<ZeroDivisionError: divided by 0>)

immediate_fail = Task[:immediate] { 1/0 }
immediate_fail # => Task(error=#<ZeroDivisionError: divided by 0>)
```

You can process failures with `or` and `or_fmap`:

```ruby
Task[:immediate] { 1/0 }.or { M::Task[:immediate] { 0 } } # => Task(value=0)
Task[:immediate] { 1/0 }.or_fmap { 0 } # => Task(value=0)
```

### Extracting result

Getting the result of a task is an unsafe operation, it blocks the current thread until the task is finished, then returns the value or raises an exception if the evaluation wasn't sucessful. It effectively cancels all niceties of tasks so you shouldn't use it in production code.

```ruby
Task { 0 }.value! # => 0
Task { 1/0 }.value! # => ZeroDivisionError: divided by 0
```

You can wait for a task to complete, the `wait` method accepts an optional timeout. `.wait` returns the task back, without unwrapping the result so it's a blocking yet safe operation:

```ruby
Task[:io] { 2 }.wait(1) # => Task(value=2)
Task[:io] { sleep 2; 2 }.wait(1) # => Task(?)

# (?) denotes an unfinished computation
```

### Conversions

Tasks can be converted to other monads but keep in mind that all conversions block the current thread:

```ruby
Task[:io] { 2 }.to_result # => Success(2)
Task[:io] { 1/0 }.to_result # => Failure(#<ZeroDivisionError: divided by 0>)

Task[:io] { 2 }.to_maybe # => Some(2)
Task[:io] { 1/0 }.to_maybe # => None
```
