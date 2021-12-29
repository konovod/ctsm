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
  # define transition method `start` from `Initial` to `First`
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
    @was_reset = true
  end
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
  machine.state.should eq TestMachine::State::Initial

  # Transition to `First` state
  machine.startup
  machine.state.should eq TestMachine::State::First

  # Incorrect transitions will raise an exception
  expect_raises(CTSM::TransitionImpossible) { machine.startup }

  # ...
  machine.flip
  machine.flip
  machine.reset

```

## Development

This shard involves some macro magic, but this hopefully shouldn't affect compilation performance.

## Contributing

1. Fork it (<https://github.com/konovod/ctsm/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Andrey Konovod](https://github.com/konovod) - creator and maintainer
