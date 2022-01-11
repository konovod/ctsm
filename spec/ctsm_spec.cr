require "./spec_helper"

class TestMachine < CTSM::Machine
  property was_reset = false
  property flip_possible = false
  initial_state(Initial)
  transition(startup, Initial, to: First)
  transition_if(flip, First, to: Second) do
    @flip_possible
  end
  transition_if(flip, Second, to: First) do
    @flip_possible
  end
  transition(reset, to: First) do
    @was_reset = true
  end
  transition(wait, First, to: First)
  transition(wait, Second, to: Second)
  transition(wait, WrongCondition, to: Second) # should produce warning
  transition(breaks, First, to: DeadEnd)       # won't produce warning as there is `reset`

  transition(support_underscores1, First, to: First)
  transition(support_underscores2, First, to: Second)

  property count_enters = 0
  property count_leaves = 0
  property from_state = State::Initial
  property to_state = State::Initial

  before Second do
    @count_enters += 1
    @from_state = @state
  end
  after Second do
    @count_leaves += 1
    @to_state = @state
  end

  # initial_state(Initial2)                  # should be compile-time error
  # transition(startup, Initial, to: First)  # should be compile-time error
  # transition(reset, to: First)             # should be compile-time error
  # before(Second) { }                       # should be compile-time error
  # after(Second) { }                        # should be compile-time error
  # transition(startup, Initial, to: Second) # should be compile-time error
  # transition(startup, to: First)           # should be compile-time error
  # transition(reset, Second, to: First)     # should be compile-time error
  # transition(reset, to: Second)            # should be compile-time error
end

class TestMachine2 < CTSM::Machine
  initial_state(First)
  transition(flip1, First, to: Second)
  transition(flip2, Second, to: First)
  transition(reset, Second, First, to: First)
  transition(wait, First, to: DeadEnd) # should produce warning
end

describe CTSM do
  it "state machine can be created" do
    machine = TestMachine.new
    machine.state.should eq TestMachine::State::Initial
  end
  it "transitions are possible" do
    machine = TestMachine.new
    machine.startup
    machine.state.should eq TestMachine::State::First
    expect_raises(CTSM::TransitionImpossible) { machine.startup }
  end

  it "transitions block is called" do
    machine = TestMachine.new
    machine.startup
    machine.was_reset.should eq false
    machine.reset
    machine.was_reset.should eq true
    machine.reset
    machine.was_reset.should eq true
  end

  it "different machines do not interact" do
    m1 = TestMachine.new
    m2 = TestMachine2.new
    m1.state.should eq TestMachine::State::Initial
    m2.state.should eq TestMachine2::State::First
    m1.startup
    m2.flip1
    m1.state.should eq TestMachine::State::First
    m2.state.should eq TestMachine2::State::Second
  end

  it "transitions check is called" do
    machine = TestMachine.new
    machine.startup
    machine.state.should eq TestMachine::State::First
    machine.flip
    machine.state.should eq TestMachine::State::First
    machine.flip_possible = true
    machine.flip
    machine.state.should eq TestMachine::State::Second
    machine.flip
    machine.state.should eq TestMachine::State::First
    machine.flip_possible = false
    machine.flip
    machine.state.should eq TestMachine::State::First
  end

  it "can transition to same state" do
    machine = TestMachine.new
    machine.startup
    machine.state.should eq TestMachine::State::First
    machine.wait
    machine.state.should eq TestMachine::State::First
    machine.wait
    machine.state.should eq TestMachine::State::First
  end

  it "triggers on entering and leaving state are called" do
    machine = TestMachine.new
    machine.startup
    machine.count_enters.should eq 0
    machine.count_leaves.should eq 0
    machine.flip
    machine.count_enters.should eq 0
    machine.count_leaves.should eq 0
    machine.flip_possible = true
    machine.flip
    machine.count_enters.should eq 1
    machine.count_leaves.should eq 0
    machine.from_state.should eq TestMachine::State::First
    machine.wait
    machine.count_enters.should eq 1
    machine.count_leaves.should eq 0
    machine.flip
    machine.count_enters.should eq 1
    machine.count_leaves.should eq 1
    machine.to_state.should eq TestMachine::State::First
    machine.flip
    machine.count_enters.should eq 2
    machine.count_leaves.should eq 1
    machine.reset
    machine.count_enters.should eq 2
    machine.count_leaves.should eq 2
  end

  it "support transitions with underscores" do
    machine = TestMachine.new
    machine.startup
    machine.support_underscores1
    machine.support_underscores2
  end
end
