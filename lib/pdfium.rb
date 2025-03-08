# frozen_string_literal: true

require "zeitwerk"
require "ffi"

# Initialize the Zeitwerk loader
loader = Zeitwerk::Loader.new
loader.tag = "rb-pdfium"
loader.push_dir File.expand_path("..", __dir__)
loader.ignore(File.expand_path("../pdfium.rb", __FILE__))
loader.setup

# Main namespace for PDFium bindings
module Pdfium
  def self.loader registry = Zeitwerk::Registry
    @loader ||= registry.loaders.find { |loader| loader.tag == "rb-pdfium" }
  end

  # Get the path to the PDFium library
  # @return [String] Path to the PDFium library
  def self.library_path
    ENV["PDFIUM_LIBRARY_PATH"] || default_library_path
  end

  # Get the default path to the PDFium library
  # @return [String] Default path to the PDFium library
  def self.default_library_path
    case FFI::Platform::OS
    when "darwin"
      "libpdfium.dylib"
    when "linux"
      "libpdfium.so"
    when "windows"
      "pdfium.dll"
    else
      raise "Unsupported platform: #{FFI::Platform::OS}"
    end
  end
end

require_relative "pdfium/version"
require_relative "pdfium/error"
require_relative "pdfium/bindings"
require_relative "pdfium/document"
require_relative "pdfium/text"

# Register cleanup handler to destroy the PDFium library when the Ruby process exits
at_exit do
  Pdfium::Bindings.FPDF_DestroyLibrary() rescue nil
end
