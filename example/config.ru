# frozen_string_literal: true

require "./config/environment"
run Pakyow.setup(env: ENV["RACK_ENV"]).to_app
