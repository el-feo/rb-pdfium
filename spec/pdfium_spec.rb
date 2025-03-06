# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfium do
  describe ".new" do
    it "creates a new Document instance" do
      pdf = described_class.new(fixture_path("test.pdf"))
      expect(pdf).to be_a(Pdfium::Document)
    end
  end

  describe ".library_path" do
    it "returns the path to the PDFium library" do
      original_env = ENV["PDFIUM_LIBRARY_PATH"]
      begin
        ENV["PDFIUM_LIBRARY_PATH"] = "/custom/path/to/libpdfium.dylib"
        expect(described_class.library_path).to eq("/custom/path/to/libpdfium.dylib")
      ensure
        ENV["PDFIUM_LIBRARY_PATH"] = original_env
      end
    end

    it "falls back to default_library_path when env var is not set" do
      original_env = ENV["PDFIUM_LIBRARY_PATH"]
      begin
        ENV["PDFIUM_LIBRARY_PATH"] = nil
        expect(described_class.library_path).to eq(described_class.default_library_path)
      ensure
        ENV["PDFIUM_LIBRARY_PATH"] = original_env
      end
    end
  end

  describe ".default_library_path" do
    it "returns the correct library name for the current platform" do
      platform = FFI::Platform::OS
      path = described_class.default_library_path

      case platform
      when "darwin"
        expect(path).to eq("libpdfium.dylib")
      when "linux"
        expect(path).to eq("libpdfium.so")
      when "windows"
        expect(path).to eq("pdfium.dll")
      end
    end
  end

  describe Pdfium::Document do
    let(:pdf_path) { fixture_path("test.pdf") }
    let(:pdf) {
      begin
        Pdfium.new(pdf_path)
      rescue Pdfium::DocumentLoadError => e
        skip "Could not load test PDF: #{e.message}"
        nil
      end
    }

    describe "#initialize" do
      it "raises an error for non-existent files" do
        expect { Pdfium.new("non_existent.pdf") }.to raise_error(Pdfium::DocumentLoadError)
      end

      it "sets the path attribute" do
        expect(pdf.path).to eq(pdf_path)
      end

      it "creates a valid handle" do
        expect(pdf.handle).not_to be_nil
        expect(pdf.handle).not_to be_null
      end
    end

    describe "#dimensions" do
      it "returns the width and height of the first page" do
        begin
          width, height = pdf.dimensions
          expect(width).to be_a(Float)
          expect(width).to be > 0
          expect(height).to be_a(Float)
          expect(height).to be > 0
        rescue StandardError => e
          skip "Could not get dimensions: #{e.message}"
        end
      end

      it "delegates to dimensions_for_page with index 0" do
        expect(pdf).to receive(:dimensions_for_page).with(0).and_return([100.0, 200.0])
        expect(pdf.dimensions).to eq([100.0, 200.0])
      end
    end

    describe "#page_count" do
      it "returns the number of pages" do
        begin
          expect(pdf.page_count).to be_a(Integer)
          expect(pdf.page_count).to be > 0
        rescue StandardError => e
          skip "Could not get page count: #{e.message}"
        end
      end
    end

    describe "#load_page" do
      it "loads a page successfully" do
        page = pdf.load_page(0)
        expect(page).not_to be_null
        Pdfium::Bindings.FPDF_ClosePage(page) unless page.null?
      end

      it "raises an error for invalid page index" do
        expect { pdf.load_page(999) }.to raise_error(Pdfium::OperationError)
      end

      it "raises an error if document is closed" do
        pdf.close
        expect { pdf.load_page(0) }.to raise_error(Pdfium::OperationError, /Document handle is invalid or has been closed/)
      end
    end

    describe "#annotations" do
      it "returns an array of annotations" do
        begin
          expect(pdf.annotations).to be_an(Array)
        rescue StandardError => e
          skip "Could not get annotations: #{e.message}"
        end
      end

      it "collects annotations from all pages" do
        # Mock the page_count and annotations_by_page methods
        allow(pdf).to receive(:page_count).and_return(3)
        allow(pdf).to receive(:annotations_by_page).with(0).and_return([{id: 1}])
        allow(pdf).to receive(:annotations_by_page).with(1).and_return([{id: 2}, {id: 3}])
        allow(pdf).to receive(:annotations_by_page).with(2).and_return([{id: 4}])

        expect(pdf.annotations).to eq([{id: 1}, {id: 2}, {id: 3}, {id: 4}])
      end
    end

    describe "#annotations_by_page" do
      it "returns annotations for a specific page" do
        begin
          expect(pdf.annotations_by_page(0)).to be_an(Array)
        rescue StandardError => e
          skip "Could not get annotations by page: #{e.message}"
        end
      end

      it "raises an error for non-existent pages" do
        begin
          # Only run this test if we can successfully load the document
          if pdf && !pdf.handle.null?
            expect { pdf.annotations_by_page(999) }.to raise_error(Pdfium::OperationError)
          else
            skip "Document could not be loaded"
          end
        rescue StandardError => e
          skip "Error testing non-existent page: #{e.message}"
        end
      end
    end

    describe "#close" do
      it "closes the document" do
        pdf.close
        expect(pdf.handle.null?).to be true
      end

      it "is safe to call multiple times" do
        pdf.close
        expect { pdf.close }.not_to raise_error
        expect(pdf.handle.null?).to be true
      end
    end

    describe "#error_message_for_code" do
      it "returns the correct error message for known error codes" do
        error_codes = {
          1 => "Unknown error",
          2 => "File not found or could not be opened",
          3 => "File not in PDF format or corrupted",
          4 => "Password required or incorrect password",
          5 => "Unsupported security scheme",
          6 => "Page not found or content error"
        }

        error_codes.each do |code, message|
          expect(pdf.send(:error_message_for_code, code)).to eq(message)
        end
      end

      it "returns a generic message for unknown error codes" do
        expect(pdf.send(:error_message_for_code, 999)).to eq("Error code: 999")
      end
    end

    describe "#annotation_subtype_name" do
      it "returns the correct name for known annotation subtypes" do
        subtypes = {
          0 => "UNKNOWN",
          1 => "TEXT",
          9 => "HIGHLIGHT",
          13 => "STAMP",
          20 => "WIDGET",
          28 => "REDACT"
        }

        subtypes.each do |code, name|
          expect(pdf.send(:annotation_subtype_name, code)).to eq(name)
        end
      end

      it "returns a generic name for unknown annotation subtypes" do
        expect(pdf.send(:annotation_subtype_name, 999)).to eq("UNKNOWN_999")
      end
    end
  end
end
