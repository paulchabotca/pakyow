require "pakyow/support/hookable"

RSpec.describe Pakyow::Support::Hookable do
  let :events do
    [:event_one, :event_two, :event_three]
  end

  let :hookable do
    Class.new {
      include Pakyow::Support::Hookable
      known_events :event_one, :event_two, :event_three
    }
  end

  shared_examples :hookable do
    context "when defining hooks" do
      context "and the event is known" do
        let :event do
          events.first
        end

        it "defines a before hook" do
          object.before event do; end
          expect(object.hooks(:before, event)).to_not be_empty
        end

        it "defines a before hook using `on`" do
          object.on event do; end
          expect(object.hooks(:before, event)).to_not be_empty
        end

        it "defines a after hook" do
          object.after event do; end
          expect(object.hooks(:after, event)).to_not be_empty
        end

        it "defines an around hook" do
          object.around event do; end
          expect(object.hooks(:before, event)).to_not be_empty
          expect(object.hooks(:after, event)).to_not be_empty
        end
      end

      context "and the event is unknown" do
        it "fails to define the hook" do
          expect {
            object.before :unknown do; end
          }.to raise_error(ArgumentError)
        end
      end
    end

    context "when calling hooks" do
      it "passes arguments" do
        event = events.first
        calls = []

        hook_1 = -> (arg1, arg2) { calls << [arg1, arg2] }

        object.before event, &hook_1

        object.call_hooks(:before, event, :foo, :bar)

        expect(calls[0][0]).to eq :foo
        expect(calls[0][1]).to eq :bar
      end

      it "calls hooks for event in order of definition" do
        event = events.first
        calls = []

        hook_1 = -> { calls << 1 }
        hook_2 = -> { calls << 2 }
        hook_3 = -> { calls << 3 }

        object.before event, &hook_2
        object.before event, &hook_3
        object.before event, &hook_1

        object.call_hooks(:before, event)

        expect(calls[0]).to eq 2
        expect(calls[1]).to eq 3
        expect(calls[2]).to eq 1
      end
    end

    context "when calling hooks around other code execution" do
      let :event do
        events.first
      end

      let :calls do
        []
      end

      before do
        local_calls = calls

        hook_1 = -> { local_calls << 1 }
        hook_2 = -> { local_calls << 2 }

        object.before event, &hook_2
        object.after event, &hook_1

        object.performing event do
          local_calls << :yielded
        end
      end

      it "calls the before hook first" do
        expect(calls[0]).to eq 2
      end

      it "yields to the block after before hook and before after hook" do
        expect(calls[1]).to eq :yielded
      end

      it "calls the after hook last" do
        expect(calls[2]).to eq 1
      end
    end

    describe "hook context" do
      let :event do
        events.first
      end

      it "execs by default" do
        object.before event do
          $context = self
        end

        object.performing event do; end

        expect($context).to be(object)
      end

      it "execs when exec: true" do
        object.before event, exec: true do
          $context = self
        end

        object.performing event do; end

        expect($context).to be(object)
      end

      it "calls when exec: false" do
        object.before event, exec: false do
          $context = self
        end

        object.performing event do; end

        expect($context).to be(self)
      end
    end
  end

  describe "hookable class" do
    let :object do
      hookable
    end

    include_examples :hookable
  end

  describe "hookable instance" do
    let :object do
      hookable.new
    end

    include_examples :hookable
  end

  context "with hooks defined on the class and instance" do
    let :event do
      events.first
    end

    it "calls the class hooks first, regardless of the order of definition" do
      calls = []
      hook_1 = -> { calls << 1 }
      hookable.before event, &hook_1
    end
  end

  context "when calling hooks with various priorities" do
    let :event do
      events.first
    end

    it "calls hooks from highest to lowest priority" do
      calls = []

      hook_1 = -> { calls << 1 }
      hook_2 = -> { calls << 2 }
      hook_3 = -> { calls << 3 }

      hookable.before event, priority: :low, &hook_1
      hookable.before event, priority: :high, &hook_2
      hookable.before event, &hook_3

      hookable.call_hooks(:before, event)

      expect(calls[0]).to eq 2
      expect(calls[1]).to eq 3
      expect(calls[2]).to eq 1
    end

    context "when prioritized class hooks are defined" do
      it "calls hooks by order of priority, regardless of class or instance definition" do
        calls = []

        hook_1 = -> { calls << 1 }
        hook_2 = -> { calls << 2 }
        hook_3 = -> { calls << 3 }

        hookable.before event, priority: :low, &hook_1
        hookable.before event, priority: :high, &hook_2

        instance = hookable.new
        instance.before event, &hook_3

        instance.call_hooks(:before, event)

        expect(calls[0]).to eq 2
        expect(calls[1]).to eq 3
        expect(calls[2]).to eq 1
      end
    end
  end
end
