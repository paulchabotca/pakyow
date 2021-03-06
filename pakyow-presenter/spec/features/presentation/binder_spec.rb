RSpec.describe "binding data via presenter, with a binder" do
  let :post_binder do
    Pakyow::Presenter::Binder.make :post do
      def title
        object[:title].to_s.reverse
      end
    end
  end

  let :comment_binder do
    Pakyow::Presenter::Binder.make :comment do
      def body
        "comment: #{object[:body]}"
      end
    end
  end

  let :presenter do
    Pakyow::Presenter::Presenter.new(view, embed_templates: false, binders: [post_binder, comment_binder])
  end

  let :view do
    Pakyow::Presenter::View.new("<div binding=\"post\"><h1 binding=\"title\">title goes here</h1><p binding=\"body\">body goes here</p></div>")
  end

  let :post_presenter do
    presenter.find(:post)
  end

  it "uses the binder, falling back to the object when binder does not support a value" do
    post_presenter.present(title: "foo", body: "bar")
    expect(presenter.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">oof</h1><p data-b=\"body\">bar</p></div>")
  end

  context "binder defines parts" do
    let :post_binder do
      Pakyow::Presenter::Binder.make :post do
        def title
          part :content do
            object[:title].to_s.reverse
          end

          part :style do
            { color: "red" }
          end
        end
      end
    end

    it "binds each part" do
      post_presenter.present(title: "foo", body: "bar")
      expect(presenter.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\" style=\"color:red\">oof</h1><p data-b=\"body\">bar</p></div>")
    end

    context "view includes parts" do
      let :post_binder do
        Pakyow::Presenter::Binder.make :post do
          def title
            part :content do
              object[:title].to_s.reverse
            end

            part :style do
              { color: "red" }
            end

            part :title do
              "title is: #{object[:title]}"
            end
          end
        end
      end

      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\"><h1 binding=\"title\" include=\"content title\">title goes here</h1><p binding=\"body\">body goes here</p></div>")
      end

      it "binds only the included parts" do
        post_presenter.present(title: "foo", body: "bar")
        expect(presenter.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\" title=\"title is: foo\">oof</h1><p data-b=\"body\">bar</p></div>")
      end
    end

    context "view excludes parts" do
      let :post_binder do
        Pakyow::Presenter::Binder.make :post do
          def title
            part :content do
              object[:title].to_s.reverse
            end

            part :style do
              { color: "red" }
            end

            part :title do
              "title is: #{object[:title]}"
            end
          end
        end
      end

      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\"><h1 binding=\"title\" exclude=\"title\">title goes here</h1><p binding=\"body\">body goes here</p></div>")
      end

      it "binds only the non-excluded parts" do
        post_presenter.present(title: "foo", body: "bar")
        expect(presenter.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\" style=\"color:red\">oof</h1><p data-b=\"body\">bar</p></div>")
      end
    end

    context "binder defines parts, but not content" do
      let :post_binder do
        Pakyow::Presenter::Binder.make :post do
          def title
            part :style do
              { color: "red" }
            end
          end
        end
      end

      it "binds the defined parts, pulling content from object" do
        post_presenter.present(title: "foo", body: "bar")
        expect(presenter.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\" style=\"color:red\">foo</h1><p data-b=\"body\">bar</p></div>")
      end

      context "content value is not provided by the binder, and the object has no value" do
        it "leaves the value defined in the view template" do
          post_presenter.present(body: "bar")
          expect(presenter.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\" style=\"color:red\">title goes here</h1><p data-b=\"body\">bar</p></div>")
        end
      end
    end
  end

  context "nested data has a binder" do
    let :view do
      Pakyow::Presenter::View.new("<body><div binding=\"post\"><h1 binding=\"title\">title goes here</h1><div binding=\"comment\"><p binding=\"body\">comment body goes here</p></div></body>")
    end

    it "uses the binder" do
      post_presenter.present(title: "post", comment: { body: "comment" })
      expect(presenter.to_s).to eq("<body><div data-b=\"post\"><h1 data-b=\"title\">tsop</h1><div data-b=\"comment\"><p data-b=\"body\">comment: comment</p></div></div></body>")
    end
  end

  context "binding tries to build a url" do
    include_context "testable app"

    let :app_definition do
      Proc.new {
        resource :post, "/posts" do
          show do; end
        end
      }
    end

    let :post_binder do
      Pakyow::Presenter::Binder.make :post do
        def permalink
          part :href do
            path(:post_show, id: object[:id])
          end
        end
      end
    end

    let :presenter do
      Pakyow::Presenter::Presenter.new(view, endpoints: Pakyow.apps[0].endpoints, embed_templates: false, binders: [post_binder, comment_binder])
    end

    let :view do
      Pakyow::Presenter::View.new("<body><div binding=\"post\"><a binding=\"permalink\">permalink</a></div></body>")
    end

    it "builds the url" do
      post_presenter.present(id: 1)
      expect(presenter.to_s).to eq("<body><div data-b=\"post\" data-id=\"1\"><a data-b=\"permalink\" href=\"/posts\">permalink</a></div></body>")
    end
  end
end
