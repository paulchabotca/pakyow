RSpec.describe "setting up a form via presenter" do
  let :presenter do
    Pakyow::Presenter::Presenter.new(view)
  end

  let :view do
    Pakyow::Presenter::View.new(
      <<~HTML
        <form binding=\"post\">
          <input binding=\"title\" type="text">
          <input@foo type="text" name="foo">
          <input@published type="checkbox" value="true">
          <input@public type="checkbox" value="true">
          <input@public type="checkbox" value="false">
        </form>
      HTML
    )
  end

  let :form do
    presenter.form(:post)
  end

  describe "setting up the form for creating an object" do
    let :object do
      { title: "foo" }
    end

    it "sets the form method" do
      form.create(object)
      expect(form.attrs[:method]).to eq("post")
    end

    it "binds the values" do
      form.create(object)
      expect(form.find(:title).attrs[:value]).to eq("foo")
    end

    it "does not create the method override field" do
      form.create(object)
      expect(presenter.to_s).not_to include("<input type=\"hidden\" name=\"_method\"")
    end

    context "matching route is found" do
      include_context "testable app"

      let :app_definition do
        Proc.new {
          resource :post, "/posts" do
            create do; end
          end
        }
      end

      let :presenter do
        Pakyow::Presenter::Presenter.new(view, endpoints: Pakyow.apps[0].endpoints)
      end

      it "sets the form action" do
        form.create(object)
        expect(form.attrs[:action]).to eq("/posts")
      end
    end

    context "matching route is not found" do
      it "does not set the form action" do
        form.create(object)
        expect(form.attrs[:action]).to eq(nil)
      end
    end

    context "block is given" do
      it "yields form to the block" do
        expect { |b| form.create(object, &b) }.to yield_with_args(form)
      end
    end
  end

  describe "setting up the form for updating" do
    let :object do
      { id: 1, title: "bar" }
    end

    it "sets the form method" do
      form.update(object)
      expect(form.attrs[:method]).to eq("post")
    end

    it "creates the method override field" do
      form.update(object)
      expect(presenter.to_s).to include("<input type=\"hidden\" name=\"_method\" value=\"patch\">")
    end

    it "binds the values" do
      form.update(object)
      expect(form.find(:title).attrs[:value]).to eq("bar")
    end

    context "matching route is found" do
      include_context "testable app"

      let :app_definition do
        Proc.new {
          resource :post, "/posts" do
            update do; end
          end
        }
      end

      let :presenter do
        Pakyow::Presenter::Presenter.new(view, endpoints: Pakyow.apps[0].endpoints)
      end

      it "sets the form action" do
        form.update(object)
        expect(form.attrs[:action]).to eq("/posts/1")
      end
    end

    context "matching route is not found" do
      it "does not set the form action" do
        form.create(object)
        expect(form.attrs[:action]).to eq(nil)
      end
    end

    context "block is given" do
      it "yields form to the block" do
        expect { |b| form.update(object, &b) }.to yield_with_args(form)
      end
    end
  end

  describe "setting up the form for replacing" do
    let :object do
      { id: 1, title: "bar" }
    end

    it "sets the form method" do
      form.replace(object)
      expect(form.attrs[:method]).to eq("post")
    end

    it "creates the method override field" do
      form.replace(object)
      expect(presenter.to_s).to include("<input type=\"hidden\" name=\"_method\" value=\"put\">")
    end

    it "binds the values" do
      form.replace(object)
      expect(form.find(:title).attrs[:value]).to eq("bar")
    end

    context "matching route is found" do
      include_context "testable app"

      let :app_definition do
        Proc.new {
          resource :post, "/posts" do
            replace do; end
          end
        }
      end

      let :presenter do
        Pakyow::Presenter::Presenter.new(view, endpoints: Pakyow.apps[0].endpoints)
      end

      it "sets the form action" do
        form.replace(object)
        expect(form.attrs[:action]).to eq("/posts/1")
      end
    end

    context "matching route is not found" do
      it "does not set the form action" do
        form.create(object)
        expect(form.attrs[:action]).to eq(nil)
      end
    end

    context "block is given" do
      it "yields form to the block" do
        expect { |b| form.replace(object, &b) }.to yield_with_args(form)
      end
    end
  end

  describe "setting up the form for removing" do
    let :object do
      { id: 1, title: "bar" }
    end

    it "sets the form method" do
      form.remove(object)
      expect(form.attrs[:method]).to eq("post")
    end

    it "creates the method override field" do
      form.remove(object)
      expect(presenter.to_s).to include("<input type=\"hidden\" name=\"_method\" value=\"delete\">")
    end

    it "binds the values" do
      form.remove(object)
      expect(form.find(:title).attrs[:value]).to eq("bar")
    end

    context "matching route is found" do
      include_context "testable app"

      let :app_definition do
        Proc.new {
          resource :post, "/posts" do
            remove do; end
          end
        }
      end

      let :presenter do
        Pakyow::Presenter::Presenter.new(view, endpoints: Pakyow.apps[0].endpoints)
      end

      it "sets the form action" do
        form.remove(object)
        expect(form.attrs[:action]).to eq("/posts/1")
      end
    end

    context "matching route is not found" do
      it "does not set the form action" do
        form.create(object)
        expect(form.attrs[:action]).to eq(nil)
      end
    end

    context "block is given" do
      it "yields form to the block" do
        expect { |b| form.remove(object, &b) }.to yield_with_args(form)
      end
    end
  end
end
