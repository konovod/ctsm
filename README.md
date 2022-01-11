<a href="https://github.com/konovod/ctsm/actions/workflows/ci.yml">
  <img src="https://github.com/konovod/ctsm/actions/workflows/ci.yml/badge.svg" alt="Build Status">
</a>

# ctsm

This shard provides Finite State Machines (FSMs) that is type-safe (states are Enum instead of Symbol, transitions are methods, so typo will result in compilation error instead of runtime exception) and DSL for states definition (no need to declare all states, just define all transitions).

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     ctsm:
       github: konovod/ctsm
   ```

2. Run `shards install`

## Usage

```crystal
require "ctsm"

class TestMachine < CTSM::Machine
  # initial state (required)
  initial_state(Initial)

  # define transition method `startup` from `Initial` to `First`
  transition(startup, Initial, to: First)

  # define transition method that checks a condition
  transition_if(flip, First, to: Second) do
    ticks_passed > 500
  end

  # same transition methods can be defined more then once 
  # (from  different states)
  transition_if(flip, Second, to: First) do
    ticks_passed > 500
  end

  # define transition method from any state to `First`
  transition(reset, to: First) do
    # block in a `transition` is called after state was changed
    @was_reset = true
  end

  # you can also define a transition from a list of states
  transition(reset2, First, Second, to: First)

  # define transition method from `First` to `First`
  transition(wait, First, to: First)
  # and from `Second` to `Second`
  transition(wait, Second, to: Second)

  # define trigger that is called every time before entering `Second` state
  before Second do
    # `@state` is equal to the previous state at this point
    puts "Entering Second from #{@state}"
  end

  # define trigger that is called every time after leaving `Second` state
  after Second do
    # `@state` is equal to the next state at this point
    puts "Leaving from Second to #{@state}"
  end
end

# Usage:
  machine = TestMachine.new # creates machine with initial state
  machine.state # => TestMachine::State::Initial

  # Transition to `First` state
  machine.startup
  machine.state # => TestMachine::State::First

  # Incorrect transitions will raise an exception
  machine.startup # raises CTSM::TransitionImpossible

  # ...
  machine.flip
  machine.flip
  machine.reset

```

### Order of calls
  When transiting, methods are executed in following order:
  1. Condition in `transition_if` checked
  2. `before` of the new state is called
  3. `@state = newstate`
  4. `after` of old state is called
  5. Block in `transition` is called

Note 1. and 5. are currently mutually-exclusive.
Order of (2), (3) and (4) is somewhat counterintuitive, but allow to `@state` has an old value in case of `before` and new value in case of `after`, thus giving full information about transition without passing additional params.

TODO - more flexible order

### Compile-time Checks
Compiler will issue an error in following cases:
  1. `initial_state` is not defined
  2. `initial_state` is defined more than once
  3. `before` is defined more than once for same state
  4. `after` is defined more than once for same state
  5. Same transition is defined from the same state more than once
  6. Same transition is defined more than once and at least one definition is from "any_state"
Also, compile-time warning issued in following cases (that most likely means error but can also happen while debugging)
  1. There is a state that isn't reachable with any transition
  2. There is a state that has no possible transitions from it (note that any transition from "any_state" disable this warning as technically it can happen from any state).

## Development

This shard involves some macro magic, but this hopefully shouldn't affect compilation performance. According to my benchmark, compilation takes less than 0.05s for a machine with 100 states and 2.5s for (unrealistic) case with 1000 states.

### Roadmap
- [ ] flexible order of triggers (entering/leaving/entered/left)
- [x] configurable prefix instead of `internal` to avoid name conflicts
- [ ] ability to explicitly define list of states

## Contributing

1. Fork it (<https://github.com/konovod/ctsm/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Andrey Konovod](https://github.com/konovod) - creator and maintainer
