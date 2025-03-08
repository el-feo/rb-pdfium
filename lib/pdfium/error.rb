# frozen_string_literal: true

module Pdfium
  # Base error class for PDFium-related errors
  class Error < StandardError; end

  # Error raised when the PDFium library cannot be loaded
  class LibraryNotFoundError < Error; end

  # Error raised when a PDF document cannot be loaded
  class DocumentLoadError < Error; end

  # Error raised when a PDF operation fails
  class OperationError < Error; end
end
