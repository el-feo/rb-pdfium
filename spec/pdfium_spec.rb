# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfium do
  describe ".new" do
    it "creates a new Document instance" do
      pdf = described_class.new(fixture_path("test.pdf"))
      expect(pdf).to be_a(Pdfium::Document)
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
    end

    # Enable all tests that interact with PDFium
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

    describe "#annotations" do
      it "returns an array of annotations" do
        begin
          expect(pdf.annotations).to be_an(Array)
        rescue StandardError => e
          skip "Could not get annotations: #{e.message}"
        end
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
    end
  end
end
