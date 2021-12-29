# TODO: Write documentation for `Ctsm`
module CTSM
  class TransitionImpossible < Exception
  end

  class Machine
    macro initial_state(x)
      getter state = State::{{x}}
    end

    macro transition(method, *afrom, to, &)
      def {{method}}
        froms = {{afrom.map { |x| ("State::#{x}").id }}}
        raise CTSM::TransitionImpossible.new("#{self.class}: Transition {{method}} impossible for state #{@state}") unless froms.includes? @state
        @state = State::{{to}}
        {{yield}}
      end
    end

    macro transition_if(method, *afrom, to, &)
      def {{method}}
        froms = {{afrom.map { |x| ("State::#{x}").id }}}
        raise CTSM::TransitionImpossible.new("#{self.class}: Transition {{method}} impossible for state #{@state}") unless froms.includes? @state
        return unless {{yield}}
        @state = State::{{to}}
      end
    end

    macro finished
      enum State
        Initial
        First
        Second
      end
      
    end
  end
end
