RSpec.describe "binding data via presenter" do
  let :presenter do
    Pakyow::Presenter::Presenter.new(view, embed_templates: false)
  end

  let :view do
    Pakyow::Presenter::View.new("<div binding=\"post\"><h1 binding=\"title\">title goes here</h1><p binding=\"body\">body goes here</p></div>")
  end

  let :post_presenter do
    presenter.find(:post)
  end

  it "binds a single value" do
    post_presenter.bind(title: "foo")
    expect(presenter.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">foo</h1><p data-b=\"body\">body goes here</p></div>")
  end

  it "binds multiple values" do
    post_presenter.bind(title: "foo", body: "bar")
    expect(presenter.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">foo</h1><p data-b=\"body\">bar</p></div>")
  end

  it "returns self" do
    expect(post_presenter.bind(title: "foo", body: "bar")).to be(post_presenter)
  end

  context "binding a nonexistent value" do
    it "ignores the nonexistent bindings" do
      post_presenter.bind(title: "foo", body: "bar", baz: "baz")
      expect(presenter.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">foo</h1><p data-b=\"body\">bar</p></div>")
    end

    it "returns self" do
      expect(post_presenter.bind(title: "foo", body: "bar", baz: "baz")).to be(post_presenter)
    end
  end

  context "binding an object with an id" do
    before do
      post_presenter.bind(id: 1, title: "foo", body: "bar")
    end

    it "sets the data-id attribute" do
      expect(presenter.to_s).to eq("<div data-b=\"post\" data-id=\"1\"><h1 data-b=\"title\">foo</h1><p data-b=\"body\">bar</p></div>")
    end

    it "returns self" do
      expect(post_presenter.bind(id: 1, title: "foo", body: "bar")).to be(post_presenter)
    end
  end

  context "binding nil" do
    it "does not explode" do
      expect { post_presenter.bind(nil) }.not_to raise_error
    end

    it "leaves the view intact" do
      post_presenter.bind(nil)
      expect(presenter.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">title goes here</h1><p data-b=\"body\">body goes here</p></div>")
    end

    it "returns self" do
      expect(post_presenter.bind(nil)).to be(post_presenter)
    end
  end
end
