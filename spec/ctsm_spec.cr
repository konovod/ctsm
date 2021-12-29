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
  transition(reset, Second, First, to: First) do
    @was_reset = true
  end
  transition(wait, First, to: First)
end

class TestMachine2 < CTSM::Machine
  initial_state(First)
  transition(flip1, First, to: Second)
  transition(flip2, Second, to: First)
  transition(reset, Second, First, to: First)
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
end
