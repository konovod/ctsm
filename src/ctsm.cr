# TODO: Write documentation for `Ctsm`
module CTSM
  class TransitionImpossible < Exception
  end

  class Machine
    macro initial_state(x)
      getter state = State::{{x}}
      {% if @type.methods.map(&.name).includes? "initial_state_defined" %}
        {% raise "initial_state is already defined" %}
      {% end %}
      def initial_state_defined
      end
    end

    macro transition(method, *afrom, to, &block)
      {% if afrom.size > 0 %}
        {% for from_state in afrom %}
          private def transitioninternal_{{method}}_from_{{from_state}}_to_{{to}}
            @state = State::{{to}}
            {{yield}} 
          end
        {% end %}
      {% else %} 
        private def transitioninternal_{{method}}_fromall_to_{{to}}
          @state = State::{{to}}
          {{yield}} 
        end
      {% end %}
    end

    macro transition_if(method, *afrom, to, &block)
      {% if afrom.size > 0 %}
        {% for from_state in afrom %}
          private def transitioninternal_{{method}}_from_{{from_state}}_to_{{to}}
            {% if block %}
              return unless {{yield}}
            {% else %}
              {% raise "block must be present in `transition_if`" %}
            {% end %}
            @state = State::{{to}}
          end
        {% end %}
      {% else %} 
        private def transitioninternal_{{method}}_fromall_to_{{to}}
          {% if block %}
            return unless {{yield}}
          {% else %}
            {% raise "block must be present in `transition_if`" %}
          {% end %}
          @state = State::{{to}}
        end
      {% end %}
    end

    macro inherited
    {% verbatim do %}
    macro finished
      {% if !@type.methods.map(&.name.stringify).includes?("initial_state_defined") %}
        {% raise "initial_state is not defined" %}
      {% end %}
      # gather list of states
      {% states = {} of String => Bool %}
      {% for meth in @type.methods %}
        {% name_parts = meth.name.split('_') %}
        {% if name_parts[0] == "transitioninternal" %}
          # transitioninternal_method_from_fromstate_to_tostate
          # transitioninternal_method_fromall_to_tostate
          {% if name_parts[2] == "fromall" %}
            {% states[name_parts[4]] = true %}
          {% else %}  
            {% states[name_parts[3]] = true %}
            {% states[name_parts[5]] = true %}
          {% end %}
        {% end %}
      {% end %}
      {% states = states.keys.map(&.capitalize) %}
      # now define enum  
      {% begin %}
      enum State
        {% for state in states %}
          {{state.id}}
        {% end %}
      end
      {% end %}
      {% matrix = [] of Array(String) %}
      {% any_transitions = [] of String %}



    end     
    {% end %}
    end
  end
end
