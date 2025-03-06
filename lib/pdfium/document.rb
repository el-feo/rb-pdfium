# frozen_string_literal: true

module Pdfium
  # Represents a PDF document
  class Document
    # @return [String] Path to the PDF file
    attr_reader :path

    # @return [FFI::Pointer] PDFium document handle
    attr_reader :handle

    # Initialize a new PDF document
    # @param path [String] Path to the PDF file
    # @param password [String, nil] Password for encrypted PDFs
    # @raise [DocumentLoadError] If the document cannot be loaded
    def initialize(path, password = nil)
      @path = path
      @handle = Bindings.FPDF_LoadDocument(path, password)
      
      if @handle.null?
        error_code = Bindings.FPDF_GetLastError
        error_message = error_message_for_code(error_code)
        raise DocumentLoadError, "Failed to load PDF document: #{error_message}"
      end
      
      # We no longer use a finalizer - users must explicitly call close
      # This avoids segmentation faults during garbage collection
    end

    # Create a finalizer proc to close the document when the object is garbage collected
    # This method is kept for backward compatibility but is no longer used
    # @param handle [FFI::Pointer] PDFium document handle
    # @return [Proc] Finalizer proc
    def self.finalize(handle)
      # Return an empty proc that does nothing
      proc {}
    end

    # Close the document
    # @return [void]
    def close
      unless @handle.nil? || @handle.null?
        begin
          Bindings.FPDF_CloseDocument(@handle)
        rescue => e
          # Log the error but don't crash
          warn "Error closing PDF document: #{e.message}"
        ensure
          # Always set the handle to NULL to prevent double-free
          @handle = FFI::Pointer::NULL
        end
      end
    end

    # Get the number of pages in the document
    # @return [Integer] Number of pages
    def page_count
      Bindings.FPDF_GetPageCount(@handle)
    end

    # Get the dimensions of the document (first page)
    # @return [Array<Float>] Width and height of the document in points [width, height]
    def dimensions
      dimensions_for_page(0)
    end

    # Get the dimensions of a specific page
    # @param page_index [Integer] Zero-based page index
    # @return [Array<Float>] Width and height of the page in points [width, height]
    def dimensions_for_page(page_index)
      page = load_page(page_index)
      begin
        width = Bindings.FPDF_GetPageWidth(page)
        height = Bindings.FPDF_GetPageHeight(page)
        [width, height]
      ensure
        Bindings.FPDF_ClosePage(page) unless page.null?
      end
    end

    # Load a page from the document
    # @param page_index [Integer] Zero-based page index
    # @return [FFI::Pointer] PDFium page handle
    # @raise [OperationError] If the page cannot be loaded
    def load_page(page_index)
      if @handle.nil? || @handle.null?
        raise OperationError, "Document handle is invalid or has been closed"
      end
      
      page = Bindings.FPDF_LoadPage(@handle, page_index)
      if page.null?
        error_code = Bindings.FPDF_GetLastError
        error_message = error_message_for_code(error_code)
        raise OperationError, "Failed to load page #{page_index}: #{error_message}"
      end
      page
    end

    # Get all annotations in the document
    # @return [Array<Hash>] Array of annotation information
    def annotations
      result = []
      
      page_count.times do |page_index|
        result.concat(annotations_by_page(page_index))
      end
      
      result
    end

    # Get annotations for a specific page
    # @param page_index [Integer] Zero-based page index
    # @return [Array<Hash>] Array of annotation information for the page
    def annotations_by_page(page_index)
      page = load_page(page_index)
      result = []
      
      begin
        annot_count = Bindings.FPDFPage_GetAnnotCount(page)
        
        annot_count.times do |annot_index|
          annot = Bindings.FPDFPage_GetAnnot(page, annot_index)
          next if annot.null?
          
          subtype = Bindings.FPDFAnnot_GetSubtype(annot)
          
          # Get annotation rectangle
          rect_ptr = FFI::MemoryPointer.new(:float, 4)
          Bindings.FPDFAnnot_GetRect(annot, rect_ptr)
          rect = rect_ptr.read_array_of_float(4)
          
          # Get annotation content (if it has a contents key)
          contents = ""
          if Bindings.FPDFAnnot_HasKey(annot, "Contents")
            # First call to get the required buffer size
            buffer_size = Bindings.FPDFAnnot_GetStringValue(annot, "Contents", nil, 0)
            
            if buffer_size > 0
              buffer = FFI::MemoryPointer.new(:char, buffer_size)
              Bindings.FPDFAnnot_GetStringValue(annot, "Contents", buffer, buffer_size)
              contents = buffer.read_string(buffer_size - 1) # -1 to exclude null terminator
            end
          end
          
          result << {
            page: page_index,
            index: annot_index,
            subtype: annotation_subtype_name(subtype),
            rect: {
              left: rect[0],
              bottom: rect[1],
              right: rect[2],
              top: rect[3]
            },
            contents: contents
          }
        end
      ensure
        Bindings.FPDF_ClosePage(page) unless page.null?
      end
      
      result
    end

    private

    # Get the error message for a PDFium error code
    # @param error_code [Integer] PDFium error code
    # @return [String] Error message
    def error_message_for_code(error_code)
      case error_code
      when 1
        "Unknown error"
      when 2
        "File not found or could not be opened"
      when 3
        "File not in PDF format or corrupted"
      when 4
        "Password required or incorrect password"
      when 5
        "Unsupported security scheme"
      when 6
        "Page not found or content error"
      else
        "Error code: #{error_code}"
      end
    end

    # Get the name of an annotation subtype
    # @param subtype [Integer] Annotation subtype code
    # @return [String] Annotation subtype name
    def annotation_subtype_name(subtype)
      case subtype
      when 0 then "UNKNOWN"
      when 1 then "TEXT"
      when 2 then "LINK"
      when 3 then "FREETEXT"
      when 4 then "LINE"
      when 5 then "SQUARE"
      when 6 then "CIRCLE"
      when 7 then "POLYGON"
      when 8 then "POLYLINE"
      when 9 then "HIGHLIGHT"
      when 10 then "UNDERLINE"
      when 11 then "SQUIGGLY"
      when 12 then "STRIKEOUT"
      when 13 then "STAMP"
      when 14 then "CARET"
      when 15 then "INK"
      when 16 then "POPUP"
      when 17 then "FILEATTACHMENT"
      when 18 then "SOUND"
      when 19 then "MOVIE"
      when 20 then "WIDGET"
      when 21 then "SCREEN"
      when 22 then "PRINTERMARK"
      when 23 then "TRAPNET"
      when 24 then "WATERMARK"
      when 25 then "THREED"
      when 26 then "RICHMEDIA"
      when 27 then "XFAWIDGET"
      when 28 then "REDACT"
      else "UNKNOWN_#{subtype}"
      end
    end
  end

  # Convenience class method to create a new Document instance
  # @param path [String] Path to the PDF file
  # @param password [String, nil] Password for encrypted PDFs
  # @return [Document] New Document instance
  def self.new(path, password = nil)
    Document.new(path, password)
  end
end
