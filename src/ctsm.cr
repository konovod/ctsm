# TODO: Write documentation for `Ctsm`
module CTSM
  class TransitionImpossible < Exception
  end

  class Machine
    macro initial_state(x)
      {% if @type.methods.map(&.name).includes? "internalinitial_state_defined" %}
        {% raise "initial_state already defined" %}
      {% end %}
      private def internalinitialstatedefined
      end
      private def internalinitial_{{x}}
      end
    end

    macro transition(amethod, *afrom, to, &block)
      {% if afrom.size > 0 %}
        {% for from_state in afrom %}
          private def internaltransition_{{amethod}}_from_{{from_state}}_to_{{to}}
            @state = State::{{to}}
            {{yield}} 
          end
        {% end %}
      {% else %} 
        private def internaltransition_{{amethod}}_fromall_to_{{to}}
          @state = State::{{to}}
          {{yield}} 
        end
      {% end %}
    end

    macro transition_if(amethod, *afrom, to, &block)
      {% if afrom.size > 0 %}
        {% for from_state in afrom %}
          private def internaltransition_{{amethod}}_from_{{from_state}}_to_{{to}}
            {% if block %}
              return unless {{yield}}
            {% else %}
              {% raise "block must be present in `transition_if`" %}
            {% end %}
            @state = State::{{to}}
          end
        {% end %}
      {% else %} 
        private def internaltransition_{{amethod}}_fromall_to_{{to}}
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
      {% if !@type.methods.map(&.name.stringify).includes?("internalinitialstatedefined") %}
        {% raise "initial_state is not defined" %}
      {% end %}
      # gather list of states
      {% states_found = {} of String => Bool %}
      {% reachable = {} of String => Bool %}
      {% transitions = {} of String => Bool %}
      {% initial_state = "" %}
      {% for meth in @type.methods %}
        {% name_parts = meth.name.split('_') %}
        {% if name_parts[0] == "internaltransition" %}
          {% transitions[name_parts[1]] = true %}
          # transitioninternal_method_from_fromstate_to_tostate
          # transitioninternal_method_fromall_to_tostate
          {% if name_parts[2] == "fromall" %}
            {% states_found[name_parts[4]] = true %}
            {% reachable[name_parts[4]] = true %}
          {% else %}  
            {% states_found[name_parts[3]] = true %}
            {% reachable[name_parts[5]] = true %}
          {% end %}
        {% elsif name_parts[0] == "internalinitial" %}  
          {% reachable[name_parts[1]] = true %}
          {% initial_state = name_parts[1] %}
        {% end %}
      {% end %}
      {% for state in states_found.keys %}
        {% if !reachable[state] %}
          {% puts " WARNING: State #{state} is not reachable with any transition" %}
        {% end %}
      {% end %}
      {% states = {} of String => Int32 %}
      {% states[initial_state] = 0 %}
      {% n = 1 %}
      {% for state in states_found.keys %}
        {% if state != initial_state %}
          {% states[state] = n %}
          {% n += 1 %}
        {% end %}
      {% end %}
      {% transitions = transitions.keys %}
      # now define enum  
      {% begin %}
      enum State
        {% for state in states %}
          {{state.id}}
        {% end %}
      end
      getter state = State::{{initial_state.id}}
      {% end %}
      #build a matrix of transition methods
      {% for transition in transitions %}
        {% list = {} of String => String %}
        {% multi_defined = false %}
        {% for meth in @type.methods %}
          {% name_parts = meth.name.split('_') %}
          {% if name_parts[0] == "internaltransition" && name_parts[1] == transition %}
            # transitioninternal_method_from_fromstate_to_tostate
            # transitioninternal_method_fromall_to_tostate
            {% if name_parts[2] == "fromall" %}
              {% target = name_parts[4] %}
              {% if multi_defined || list.size > 0 %}
                {% raise "transition #{transition} is defined more than once in incompatible way" %}
              {% else %}
                {% multi_defined = true %}
                def {{transition.id}}
                  transitioninternal_method_fromall_to_{{target}}
                end
              {% end %}
          {% else %}  
              {% afrom = name_parts[3] %}
              {% ato = name_parts[5] %}
              {% if multi_defined || list[afrom] %}
                {% raise "transition #{transition} is defined more than once in incompatible way: #{list}" %}
              {% else %}
                {% list[afrom] = meth.name.stringify %}
              {% end %}
            {% end %}
          {% end %}
          {% if !multi_defined %}
            {% begin %}
            def {{transition.id}}
              case @state
                {% for afrom, meth_name in list %}
              when State::{{afrom.id}}
                {{meth_name.id}}
                {% end %}
              else 
                raise CTSM::TransitionImpossible.new("#{self.class}: Transition `{{transition.id}}` is not possible for state #{@state}")
              end
            end
            {% end %}
          {% end %}
        {% end %}
      {% end %}
    end     
    {% end %}
    end
  end
end
