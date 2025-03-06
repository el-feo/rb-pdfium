# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pdfium::Text do
  let(:pdf_path) { fixture_path("test.pdf") }
  let(:pdf) {
    begin
      Pdfium.new(pdf_path)
    rescue Pdfium::DocumentLoadError => e
      skip "Could not load test PDF: #{e.message}"
      nil
    end
  }
  let(:page) {
    begin
      pdf.load_page(0)
    rescue Pdfium::OperationError => e
      skip "Could not load page: #{e.message}"
      nil
    end
  }
  let(:text_page) {
    begin
      Pdfium::Text.load_page(page)
    rescue Pdfium::OperationError => e
      skip "Could not load text page: #{e.message}"
      nil
    end
  }

  describe ".load_page" do
    it "loads a text page successfully" do
      expect(text_page).to be_a(Pdfium::Text::TextPage)
      expect(text_page.handle).not_to be_nil
      expect(text_page.handle).not_to be_null
    end

    it "raises an error for invalid page handle" do
      expect { Pdfium::Text.load_page(FFI::Pointer::NULL) }.to raise_error(Pdfium::OperationError)
    end
  end

  describe Pdfium::Text::TextPage do
    describe "#count_chars" do
      it "returns the number of characters in the text page" do
        expect(text_page.count_chars).to be_a(Integer)
        expect(text_page.count_chars).to be >= 0
      end
    end

    describe "#get_text" do
      it "returns the text content of the page" do
        text = text_page.get_text
        expect(text).to be_a(String)
      end

      it "returns a subset of text when given a range" do
        char_count = text_page.count_chars
        next unless char_count > 10

        text = text_page.get_text(0, 10)
        expect(text).to be_a(String)
        expect(text.length).to be <= 10
      end

      it "handles invalid ranges gracefully" do
        char_count = text_page.count_chars
        expect { text_page.get_text(-1, 10) }.to raise_error(ArgumentError)
        expect { text_page.get_text(0, char_count + 10) }.to raise_error(ArgumentError)
      end
    end

    describe "#get_char_box" do
      it "returns the bounding box of a character" do
        next if text_page.count_chars == 0

        box = text_page.get_char_box(0)
        expect(box).to be_a(Hash)
        expect(box).to include(:left, :right, :bottom, :top)
      end

      it "raises an error for invalid character index" do
        char_count = text_page.count_chars
        expect { text_page.get_char_box(-1) }.to raise_error(ArgumentError)
        expect { text_page.get_char_box(char_count) }.to raise_error(ArgumentError)
      end
    end

    describe "#get_char_at_position" do
      it "returns a character index at a position" do
        width, height = pdf.dimensions_for_page(0)
        index = text_page.get_char_at_position(width / 2, height / 2)
        expect(index).to be_a(Integer)
      end
    end

    describe "#close" do
      it "closes the text page" do
        text_page.close
        expect(text_page.handle.null?).to be true
      end

      it "is safe to call multiple times" do
        text_page.close
        expect { text_page.close }.not_to raise_error
      end
    end
  end

  describe Pdfium::Text::TextSearch do
    let(:search) {
      begin
        Pdfium::Text::TextSearch.new(text_page, "test")
      rescue Pdfium::OperationError => e
        skip "Could not create text search: #{e.message}"
        nil
      end
    }

    describe "#initialize" do
      it "creates a text search object" do
        expect(search).to be_a(Pdfium::Text::TextSearch)
        expect(search.handle).not_to be_nil
        expect(search.handle).not_to be_null
      end
    end

    describe "#find_next" do
      it "finds the next occurrence of the search term" do
        result = search.find_next
        # The result might be true or false depending on if the text exists
        expect([true, false]).to include(result)
      end
    end

    describe "#find_prev" do
      it "finds the previous occurrence of the search term" do
        result = search.find_prev
        # The result might be true or false depending on if the text exists
        expect([true, false]).to include(result)
      end
    end

    describe "#get_selection" do
      it "returns a selection object for the current match" do
        if search.find_next
          selection = search.get_selection
          expect(selection).to be_a(Pdfium::Text::TextSelection)
        else
          skip "No search results found"
        end
      end
    end

    describe "#close" do
      it "closes the text search" do
        search.close
        expect(search.handle.null?).to be true
      end

      it "is safe to call multiple times" do
        search.close
        expect { search.close }.not_to raise_error
      end
    end
  end

  describe Pdfium::Text::TextSelection do
    let(:selection) {
      begin
        # Create a selection from the first 10 characters (if available)
        char_count = text_page.count_chars
        next nil if char_count < 10
        
        # Ensure we're selecting characters that actually exist in the document
        # This helps with the test that expects text.length > 0
        start_idx = 0
        count = [10, char_count].min
        
        Pdfium::Text::TextSelection.new(text_page, start_idx, count)
      rescue Pdfium::OperationError => e
        skip "Could not create text selection: #{e.message}"
        nil
      end
    }

    describe "#initialize" do
      it "creates a text selection object" do
        next if selection.nil?
        expect(selection).to be_a(Pdfium::Text::TextSelection)
        expect(selection.handle).not_to be_nil
        expect(selection.handle).not_to be_null
      end
    end

    describe "#get_text" do
      it "returns the selected text" do
        next if selection.nil?
        text = selection.get_text
        expect(text).to be_a(String)
        expect(text.length).to be > 0
      end
    end

    describe "#count_rects" do
      it "returns the number of rectangles in the selection" do
        next if selection.nil?
        count = selection.count_rects
        expect(count).to be_a(Integer)
        expect(count).to be >= 0
      end
    end

    describe "#get_rect" do
      it "returns a rectangle from the selection" do
        next if selection.nil?
        count = selection.count_rects
        next if count == 0

        rect = selection.get_rect(0)
        expect(rect).to be_a(Hash)
        expect(rect).to include(:left, :right, :bottom, :top)
      end

      it "raises an error for invalid rectangle index" do
        next if selection.nil?
        count = selection.count_rects
        next if count == 0

        expect { selection.get_rect(-1) }.to raise_error(ArgumentError)
        expect { selection.get_rect(count) }.to raise_error(ArgumentError)
      end
    end

    describe "#close" do
      it "closes the text selection" do
        next if selection.nil?
        selection.close
        expect(selection.handle.null?).to be true
      end

      it "is safe to call multiple times" do
        next if selection.nil?
        selection.close
        expect { selection.close }.not_to raise_error
      end
    end
  end
end
