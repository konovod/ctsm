# TODO: Write documentation for `Ctsm`

module CTSM
  PREFIX = "internal"

  class TransitionImpossible < Exception
  end

  class Machine
    macro initial_state(x)
      {% if @type.methods.map(&.name.stringify).includes? CTSM::PREFIX + "initialstatedefined" %}
        {% raise "#{@type}: initial_state already defined" %}
      {% end %}
      @[AlwaysInline]       
      private def {{CTSM::PREFIX.id}}initialstatedefined
      end
      @[AlwaysInline]       
      private def {{CTSM::PREFIX.id}}initial___{{x}}
      end
    end

    macro transition(amethod, *afrom, to, &block)
      {% if afrom.size > 0 %}
        {% for from_state in afrom %}
          {% if @type.methods.map(&.name.stringify).includes? CTSM::PREFIX + "transition___#{amethod}___from___#{from_state}___to___#{to}" %}
            {% raise "#{@type}: transition #{amethod} is defined more than once from #{from_state}" %}
          {% end %}
          @[AlwaysInline]       
          private def {{CTSM::PREFIX.id}}transition___{{amethod}}___from___{{from_state}}___to___{{to}}
            {% unless from_state == to %}
            {{CTSM::PREFIX.id}}trigger___to___{{to}}
            @state = State::{{to}}
            {{CTSM::PREFIX.id}}trigger___from___{{from_state}}
            {% end %}
            {{yield}} 
          end
        {% end %}
      {% else %} 
        {% if @type.methods.map(&.name.stringify).includes? CTSM::PREFIX + "transition___#{amethod}___fromall___to___#{to}" %}
          {% raise "#{@type}: transition #{amethod} is defined more than once from any_state" %}
        {% end %}
        @[AlwaysInline]
        private def {{CTSM::PREFIX.id}}transition___{{amethod}}___fromall___to___{{to}}
          {{CTSM::PREFIX.id}}trigger___to___{{to}}
          old_state = @state
          @state = State::{{to}}
          {{CTSM::PREFIX.id}}trigger___fromany(old_state)
          {{yield}} 
        end
      {% end %}
    end

    macro bench_transition(n, amethod, from_state, to)
      {% for i in 1..n %}
      @[AlwaysInline]       
      private def {{CTSM::PREFIX.id}}transition___{{amethod}}{{i}}___from___{{from_state}}___to___{{to}}{{i}}
        {% unless from_state == to %}
        {{CTSM::PREFIX.id}}trigger___to___{{to}}{{i}}
        @state = State::{{to}}{{i}}
        {{CTSM::PREFIX.id}}trigger___from___{{from_state}}
        {% end %}
        {{yield}} 
      end
    {% end %}

    end

    macro transition_if(amethod, *afrom, to, &block)
      {% if afrom.size > 0 %}
        {% for from_state in afrom %}
          {% if @type.methods.map(&.name.stringify).includes? CTSM::PREFIX + "transition___#{amethod}___from___#{from_state}___to___#{to}" %}
            {% raise "#{@type}: transition #{amethod} is defined more than once from #{from_state}" %}
          {% end %}
          @[AlwaysInline]
          private def {{CTSM::PREFIX.id}}transition___{{amethod}}___from___{{from_state}}___to___{{to}}
            {% if block %}
              return unless {{yield}}
            {% else %}
              {% raise "#{@type}: block must be present in `transition_if`" %}
            {% end %}
            {% unless from_state == to %}
              {{CTSM::PREFIX.id}}trigger___to___{{to}}
              @state = State::{{to}}
              {{CTSM::PREFIX.id}}trigger___from___{{from_state}}
            {% end %}
          end
        {% end %}
      {% else %} 
        {% if @type.methods.map(&.name.stringify).includes? CTSM::PREFIX + "transition___#{amethod}___fromall___to___#{to}" %}
          {% raise "#{@type}: transition #{amethod} is defined more than once from any_state" %}
        {% end %}
        @[AlwaysInline]
        private def {{CTSM::PREFIX.id}}transition___{{amethod}}___fromall___to___{{to}}
          {% if block %}
            return unless {{yield}}
          {% else %}
            {% raise "#{@type}: block must be present in `transition_if`" %}
          {% end %}
          old_state = @state
          @state = State::{{to}}
          {{CTSM::PREFIX.id}}trigger___fromany(old_state)
        end
      {% end %}
    end

    macro before(state, &block)
      {% if @type.methods.map(&.name.stringify).includes? CTSM::PREFIX + "trigger___to___#{state}" %}
        {% raise "#{@type}: trigger before #{state} is defined more than once" %}
      {% end %}
      @[AlwaysInline]
      private def {{CTSM::PREFIX.id}}trigger___to___{{state}}
        {% if block %}
          {{yield}}
        {% else %}
          {% raise "#{@type}: block must be present in `before`" %}
        {% end %}
      end
    end

    macro after(state, &block)
      {% if @type.methods.map(&.name.stringify).includes? CTSM::PREFIX + "trigger___from___#{state}" %}
        {% raise "#{@type}: trigger after #{state} is defined more than once" %}
      {% end %}
      @[AlwaysInline]
      private def {{CTSM::PREFIX.id}}trigger___from___{{state}}
        {% if block %}
          {{yield}}
        {% else %}
          {% raise "#{@type}: block must be present in `after`" %}
        {% end %}
      end
    end

    macro inherited
    {% verbatim do %}
    macro finished
      {% if !@type.methods.map(&.name.stringify).includes?(CTSM::PREFIX + "initialstatedefined") %}
        {% raise "#{@type}: initial_state is not defined" %}
      {% end %}
      # gather list of states
      {% states_found = {} of String => Bool %}
      {% reachable = {} of String => Bool %}
      {% leavable = {} of String => Bool %}
      {% all_leavable = false %}
      {% transitions = {} of String => Bool %}
      {% triggers_before = {} of String => String %}
      {% triggers_after = {} of String => String %}
      {% initial_state = "" %}
      {% for meth in @type.methods %}
        {% name_parts = meth.name.split("___") %}
        {% if name_parts[0] == CTSM::PREFIX + "transition" %}
          {% transitions[name_parts[1]] = true %}
          # internaltransition_method_from_fromstate_to_tostate
          # internaltransition_method_fromall_to_tostate
          {% if name_parts[2] == "fromall" %}
            {% states_found[name_parts[4]] = true %}
            {% reachable[name_parts[4]] = true %}
            {% all_leavable = true %}
          {% else %}  
            {% states_found[name_parts[3]] = true %}
            {% states_found[name_parts[5]] = true %}
            {% reachable[name_parts[5]] = true %}
            {% leavable[name_parts[3]] = true %}
          {% end %}
        {% elsif name_parts[0] == CTSM::PREFIX + "initial" %}  
          {% reachable[name_parts[1]] = true %}
          {% initial_state = name_parts[1] %}
        {% elsif name_parts[0] == CTSM::PREFIX + "trigger" %}  
          {% states_found[name_parts[2]] = true %}
          {% if name_parts[1] == "to" %}
            {% triggers_before[name_parts[2]] = meth.name %}
          {% else %}
            {% triggers_after[name_parts[2]] = meth.name %}
          {% end %}
        {% end %}
      {% end %}
      {% for state in states_found.keys %}
        {% if !reachable[state] %}
          {% puts " WARNING: State `#{@type.name}::State::#{state.id}` is not reachable with any transition" %}
        {% end %}
        {% if !all_leavable && !leavable[state] %}
          {% puts " WARNING: State `#{@type.name}::State::#{state.id}` has no possible transitions" %}
        {% end %}
      {% end %}
      {% for state in states_found.keys %}
        {% if !triggers_before[state] %}
          @[AlwaysInline]
          private def {{CTSM::PREFIX.id}}trigger___to___{{state.id}}
          end
        {% end %}
        {% if !triggers_after[state] %}
          @[AlwaysInline]
          private def {{CTSM::PREFIX.id}}trigger___from___{{state.id}}
          end
        {% end %}
      {% end %}
      @[AlwaysInline]
      private def {{CTSM::PREFIX.id}}trigger___fromany(old_state)
      {% if triggers_after.size == 0 %}
      {% else %}
        case old_state
          {% for astate, trigger in triggers_after %}
            when State::{{astate.id}}
              {{trigger.id}}
          {% end %}
        else
          # do nothing  
        end
      {% end %}
    end



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
          {% name_parts = meth.name.split("___") %}
          {% if name_parts[0] == CTSM::PREFIX + "transition" && name_parts[1] == transition %}
            # internaltransition_method_from_fromstate_to_tostate
            # internaltransition_method_fromall_to_tostate
            {% if name_parts[2] == "fromall" %}
              {% target = name_parts[4] %}
              {% if multi_defined %}
                {% raise "#{@type}: transition #{transition} is defined more than once from any_state" %}
              {% elsif list.size > 0 %}
                {% raise "#{@type}: transition #{transition} is defined more than once in incompatible way: from #{list.keys} and from any_state" %}
              {% else %}
                {% multi_defined = true %}
                def {{transition.id}}
                  {{CTSM::PREFIX.id}}transition___{{transition.id}}___fromall___to___{{target.id}}
                end
              {% end %}
          {% else %}  
              {% afrom = name_parts[3] %}
              {% ato = name_parts[5] %}
              {% if multi_defined %}
                {% raise "#{@type}: transition #{transition} is defined more than once in incompatible way: from any_state and from #{afrom}" %}
              {% elsif list[afrom] %}
                {% raise "#{@type}: transition #{transition} is defined more than once from #{afrom}" %}
              {% else %}
                {% list[afrom] = meth.name.stringify %}
              {% end %}
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
      #{ debug }
    end     
    {% end %}
    end
  end
end
