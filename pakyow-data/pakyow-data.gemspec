# frozen_string_literal: true

require File.expand_path("../../lib/pakyow/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name        = "pakyow-data"
  spec.version     = Pakyow::VERSION
  spec.summary     = "Pakyow Data"
  spec.description = "Data persistence layer for Pakyow"

  spec.author   = "Bryan Powell"
  spec.email    = "bryan@metabahn.com"
  spec.homepage = "https://pakyow.org"

  spec.required_ruby_version = ">= 2.4.0"

  spec.license = "MIT"

  spec.files        = Dir["CHANGELOG.md", "README.md", "LICENSE", "lib/**/*"]
  spec.require_path = "lib"

  spec.add_dependency "pakyow-support", Pakyow::VERSION

  spec.add_dependency "concurrent-ruby", "~> 1.0"
  spec.add_dependency "rom", "~> 4.1"
  spec.add_dependency "rom-sql", "~> 2.3"
end
