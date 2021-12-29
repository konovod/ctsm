require "./spec_helper"

class TestMachine < CTSM::Machine
  property was_reset = false
  initial_state(Initial)
  transition(startup, Initial, First)
  # transition_if(flip, First, to: Second) do
  #   @ticks_passed > 1000
  # end
  # transition_if(flip, Second, to: First) do
  #   @ticks_passed > 1000
  # end
  # transition(reset, Second, First, to: First) do
  #   @was_reset = true
  # end
end

describe CTSM do
  # TODO: Write tests

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
end
