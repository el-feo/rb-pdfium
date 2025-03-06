# frozen_string_literal: true

module Pdfium
  # FFI bindings for PDFium library
  module Bindings
    extend FFI::Library

    begin
      ffi_lib Pdfium.library_path
    rescue LoadError => e
      raise LibraryNotFoundError, "Failed to load PDFium library: #{e.message}. " \
                                "Set PDFIUM_LIBRARY_PATH environment variable to the correct path."
    end

    # Initialize the PDFium library
    attach_function :FPDF_InitLibrary, [], :void
    attach_function :FPDF_DestroyLibrary, [], :void

    # Call FPDF_InitLibrary when the module is loaded
    FPDF_InitLibrary()

    # Common PDFium types
    typedef :pointer, :FPDF_DOCUMENT
    typedef :pointer, :FPDF_PAGE
    typedef :pointer, :FPDF_ANNOTATION
    typedef :pointer, :FPDF_BOOKMARK
    typedef :pointer, :FPDF_TEXTPAGE
    typedef :pointer, :FPDF_SCHHANDLE
    typedef :pointer, :FPDF_BITMAP
    typedef :pointer, :FPDF_FORMHANDLE
    typedef :pointer, :FPDF_LINK
    typedef :int, :FPDF_BOOL
    typedef :int, :FPDF_ERROR
    typedef :int, :FPDF_ANNOTATION_SUBTYPE
    typedef :int, :FPDF_ANNOT_APPEARANCEMODE
    typedef :int, :FPDF_FORMTYPE
    typedef :uint32, :FPDF_DWORD
    typedef :uint32, :FPDF_DWORD32
    typedef :uint32, :FS_FLOAT
    typedef :uint32, :FPDF_RESULT

    # Helper method to safely attach functions that might not be available
    def self.safe_attach_function(name, args, returns)
      begin
        attach_function name, args, returns
      rescue FFI::NotFoundError => e
        # Function not available in this version of PDFium
        # Define a method that raises an error when called
        define_singleton_method name do |*_args|
          raise NotImplementedError, "Function #{name} is not available in your PDFium library"
        end
      end
    end

    # Document functions - these are core functions that should be available in all PDFium versions
    attach_function :FPDF_LoadDocument, [:string, :string], :FPDF_DOCUMENT
    attach_function :FPDF_LoadMemDocument, [:pointer, :int, :string], :FPDF_DOCUMENT
    attach_function :FPDF_CloseDocument, [:FPDF_DOCUMENT], :void
    attach_function :FPDF_GetPageCount, [:FPDF_DOCUMENT], :int
    attach_function :FPDF_GetPageWidth, [:FPDF_PAGE], :double
    attach_function :FPDF_GetPageHeight, [:FPDF_PAGE], :double
    attach_function :FPDF_LoadPage, [:FPDF_DOCUMENT, :int], :FPDF_PAGE
    attach_function :FPDF_ClosePage, [:FPDF_PAGE], :void
    attach_function :FPDF_GetLastError, [], :FPDF_ERROR

    # Annotation functions - some of these might not be available in all PDFium versions
    safe_attach_function :FPDFPage_GetAnnotCount, [:FPDF_PAGE], :int
    safe_attach_function :FPDFPage_GetAnnot, [:FPDF_PAGE, :int], :FPDF_ANNOTATION
    safe_attach_function :FPDFPage_CreateAnnot, [:FPDF_PAGE, :int], :FPDF_ANNOTATION
    safe_attach_function :FPDFPage_RemoveAnnot, [:FPDF_PAGE, :int], :FPDF_BOOL
    safe_attach_function :FPDFAnnot_GetSubtype, [:FPDF_ANNOTATION], :FPDF_ANNOTATION_SUBTYPE
    safe_attach_function :FPDFAnnot_GetStringValue, [:FPDF_ANNOTATION, :string, :pointer, :int], :int
    safe_attach_function :FPDFAnnot_GetObjectCount, [:FPDF_ANNOTATION], :int
    safe_attach_function :FPDFAnnot_GetPage, [:FPDF_ANNOTATION], :FPDF_PAGE
    safe_attach_function :FPDFAnnot_IsObjectVisible, [:FPDF_ANNOTATION, :int], :FPDF_BOOL
    safe_attach_function :FPDFAnnot_SetStringValue, [:FPDF_ANNOTATION, :string, :string], :FPDF_BOOL
    safe_attach_function :FPDFAnnot_SetAP, [:FPDF_ANNOTATION, :FPDF_ANNOT_APPEARANCEMODE, :string], :FPDF_BOOL
    safe_attach_function :FPDFAnnot_GetAP, [:FPDF_ANNOTATION, :FPDF_ANNOT_APPEARANCEMODE, :pointer, :int], :int
    safe_attach_function :FPDFAnnot_GetRect, [:FPDF_ANNOTATION, :pointer], :FPDF_BOOL
    safe_attach_function :FPDFAnnot_SetRect, [:FPDF_ANNOTATION, :pointer], :FPDF_BOOL
    safe_attach_function :FPDFAnnot_GetVertices, [:FPDF_ANNOTATION, :pointer, :int], :int
    safe_attach_function :FPDFAnnot_GetInkListCount, [:FPDF_ANNOTATION], :int
    safe_attach_function :FPDFAnnot_GetInkListPath, [:FPDF_ANNOTATION, :int, :pointer, :int], :int
    safe_attach_function :FPDFAnnot_GetLine, [:FPDF_ANNOTATION, :pointer, :pointer], :FPDF_BOOL
    safe_attach_function :FPDFAnnot_SetBorder, [:FPDF_ANNOTATION, :float, :float, :float], :FPDF_BOOL
    safe_attach_function :FPDFAnnot_GetBorder, [:FPDF_ANNOTATION, :pointer, :pointer, :pointer], :FPDF_BOOL
    safe_attach_function :FPDFAnnot_HasAttachmentPoints, [:FPDF_ANNOTATION], :FPDF_BOOL
    safe_attach_function :FPDFAnnot_SetColor, [:FPDF_ANNOTATION, :int, :uint, :uint, :uint, :uint], :FPDF_BOOL
    safe_attach_function :FPDFAnnot_GetColor, [:FPDF_ANNOTATION, :int, :pointer, :pointer, :pointer, :pointer], :FPDF_BOOL
    safe_attach_function :FPDFAnnot_HasKey, [:FPDF_ANNOTATION, :string], :FPDF_BOOL
    safe_attach_function :FPDFAnnot_GetValueType, [:FPDF_ANNOTATION, :string], :int
    safe_attach_function :FPDFAnnot_SetStringValue, [:FPDF_ANNOTATION, :string, :string], :FPDF_BOOL
    safe_attach_function :FPDFAnnot_GetStringValue, [:FPDF_ANNOTATION, :string, :pointer, :int], :int
    safe_attach_function :FPDFAnnot_GetNumberValue, [:FPDF_ANNOTATION, :string, :pointer], :FPDF_BOOL
    safe_attach_function :FPDFAnnot_SetNumberValue, [:FPDF_ANNOTATION, :string, :float], :FPDF_BOOL
    safe_attach_function :FPDFAnnot_GetBooleanValue, [:FPDF_ANNOTATION, :string, :pointer], :FPDF_BOOL
    safe_attach_function :FPDFAnnot_SetBooleanValue, [:FPDF_ANNOTATION, :string, :FPDF_BOOL], :FPDF_BOOL
    safe_attach_function :FPDFAnnot_GetFlags, [:FPDF_ANNOTATION], :int
    safe_attach_function :FPDFAnnot_SetFlags, [:FPDF_ANNOTATION, :int], :FPDF_BOOL
    safe_attach_function :FPDFAnnot_GetFormFieldFlags, [:FPDF_FORMHANDLE, :FPDF_ANNOTATION], :int
    safe_attach_function :FPDFAnnot_GetFormFieldAtPoint, [:FPDF_FORMHANDLE, :FPDF_PAGE, :pointer], :FPDF_ANNOTATION
    safe_attach_function :FPDFAnnot_GetFormFieldName, [:FPDF_FORMHANDLE, :FPDF_ANNOTATION, :pointer, :int], :int
    safe_attach_function :FPDFAnnot_GetFormFieldType, [:FPDF_FORMHANDLE, :FPDF_ANNOTATION], :int
    safe_attach_function :FPDFAnnot_GetFormFieldValue, [:FPDF_FORMHANDLE, :FPDF_ANNOTATION, :pointer, :int], :int
    safe_attach_function :FPDFAnnot_GetOptionCount, [:FPDF_FORMHANDLE, :FPDF_ANNOTATION], :int
    safe_attach_function :FPDFAnnot_GetOptionLabel, [:FPDF_FORMHANDLE, :FPDF_ANNOTATION, :int, :pointer, :int], :int
    safe_attach_function :FPDFAnnot_IsOptionSelected, [:FPDF_FORMHANDLE, :FPDF_ANNOTATION, :int], :FPDF_BOOL
    safe_attach_function :FPDFAnnot_GetFontSize, [:FPDF_FORMHANDLE, :FPDF_ANNOTATION, :pointer], :FPDF_BOOL
    safe_attach_function :FPDFAnnot_IsChecked, [:FPDF_FORMHANDLE, :FPDF_ANNOTATION], :FPDF_BOOL
    safe_attach_function :FPDFAnnot_SetFocusableSubtypes, [:FPDF_FORMHANDLE, :pointer, :int], :FPDF_BOOL
    safe_attach_function :FPDFAnnot_GetFocusableSubtypesCount, [:FPDF_FORMHANDLE], :int
    safe_attach_function :FPDFAnnot_GetFocusableSubtypes, [:FPDF_FORMHANDLE, :pointer, :int], :FPDF_BOOL
    safe_attach_function :FPDFAnnot_GetLink, [:FPDF_ANNOTATION], :FPDF_LINK
    safe_attach_function :FPDFAnnot_GetFormControlCount, [:FPDF_FORMHANDLE, :FPDF_ANNOTATION], :int
    safe_attach_function :FPDFAnnot_GetFormControlIndex, [:FPDF_FORMHANDLE, :FPDF_ANNOTATION, :int], :int
    safe_attach_function :FPDFAnnot_GetFormFieldExportValue, [:FPDF_FORMHANDLE, :FPDF_ANNOTATION, :pointer, :int], :int
    safe_attach_function :FPDFAnnot_SetURI, [:FPDF_ANNOTATION, :string], :FPDF_BOOL
  end
end
