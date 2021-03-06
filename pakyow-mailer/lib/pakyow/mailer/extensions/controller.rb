# frozen_string_literal: true

module Pakyow
  class Controller
    def mailer(path)
      path = String.normalize_path(path)

      if info = find_info_for(path)
        presenter = Presenter::ViewPresenter.new(
          binders: app.state_for(:binder),
          path_builder: app.path_builder,
          **info
        )

        Mailer.new(view: presenter, config: app.config.mailer)
      else
        raise Presenter::MissingView.new("No view at path `#{path}'")
      end
    end
  end
end
