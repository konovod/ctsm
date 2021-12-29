# TODO: Write documentation for `Ctsm`
module CTSM
  class TransitionImpossible < Exception
  end

  class Machine
    macro initial_state(x)
    end

    macro transition(method, afrom, ato, &)
      def {{method}}
        raise CTSM::TransitionImpossible.new("#{self.class}: Transition {{method}} impossible for state #{@state}") unless @state == State::{{afrom}}
        @state = State::{{ato}}
      end
    end

    macro transition_if(method, afrom, ato, &)
    end

    macro finished
      enum State
        Initial
        First
        Second
      end
      getter state = State::Initial
    end
  end
end
