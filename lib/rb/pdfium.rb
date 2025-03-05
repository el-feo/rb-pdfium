# frozen_string_literal: true

require "zeitwerk"

Zeitwerk::Loader.new.then do |loader|
  loader.tag = "rb-pdfium"
  loader.push_dir "#{__dir__}/.."
  loader.setup
end

module Rb
  # Main namespace.
  module Pdfium
    def self.loader registry = Zeitwerk::Registry
        @loader ||= registry.loaders.find { |loader| loader.tag == "rb-pdfium" }
  end

  end
end
