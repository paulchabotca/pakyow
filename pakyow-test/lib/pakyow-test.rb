require 'pakyow-support'
require 'pakyow-core'
require 'pakyow-presenter'
require 'pakyow-mailer'
require 'pakyow-realtime'

require_relative 'test_help/ext/request'
require_relative 'test_help/ext/response'

require_relative 'test_help/mocks/presenter_mock'
require_relative 'test_help/mocks/status_mock'

require_relative 'test_help/observables/observable_presenter'
require_relative 'test_help/observables/observable_view'
require_relative 'test_help/observables/realtime/observable_context'

require_relative 'test_help/helpers'
require_relative 'test_help/simulator'
require_relative 'test_help/simulation'

module Pakyow
  module TestHelp
    def self.setup
      Pakyow::App.stage(ENV['TEST_ENV'] || :test)

      Pakyow::App.after :match do
        @presenter = Pakyow::TestHelp::ObservablePresenter.new(@presenter)
      end
    end
  end
end

Pakyow::Presenter::ViewContext::VIEW_CLASSES << Pakyow::TestHelp::ObservableView

module Pakyow
  module Helpers
    def socket
      @socket ||= Pakyow::TestHelp::Realtime::ObservableContext.new(app)
    end
  end
end
