#!/usr/bin/env ruby
# frozen_string_literal: true

require "bundler/setup"
require "pdfium"

# Set the path to the PDFium library if needed
# ENV["PDFIUM_LIBRARY_PATH"] = "/path/to/libpdfium.dylib"

# Check if a PDF file path was provided
if ARGV.empty?
  puts "Usage: #{$PROGRAM_NAME} <path_to_pdf_file>"
  exit 1
end

pdf_path = ARGV[0]

begin
  # Open the PDF document
  puts "Opening PDF: #{pdf_path}"
  pdf = Pdfium.new(pdf_path)

  # Get basic document information
  page_count = pdf.page_count
  puts "Document information:"
  puts "- Page count: #{page_count}"

  # Process each page
  page_count.times do |page_index|
    puts "\nProcessing page #{page_index + 1}:"

    # Load the page
    page = pdf.load_page(page_index)

    # Load the text page
    text_page = Pdfium::Text.load_page(page)

    # Get character count
    char_count = text_page.count_chars
    puts "- Character count: #{char_count}"

    # Extract text from the page
    text = text_page.get_text
    puts "- Text preview: #{text[0, 100]}..." if text.length > 0

    # Search for text
    search_term = "the"
    puts "\nSearching for '#{search_term}':"
    search = text_page.create_search(search_term)

    # Find occurrences
    match_count = 0
    while search.find_next
      match_count += 1

      # Get the match details
      match_index = search.get_match_index
      match_length = search.get_match_count

      # Get the match text
      match_text = text_page.get_text(match_index, match_length)

      # Only show the first 5 matches
      if match_count <= 5
        puts "  Match #{match_count}: '#{match_text}' at index #{match_index}"

        # Get the bounding box of the first character of the match
        begin
          box = text_page.get_char_box(match_index)
          puts "    Position: left=#{box[:left].round(2)}, bottom=#{box[:bottom].round(2)}, " \
               "right=#{box[:right].round(2)}, top=#{box[:top].round(2)}"
        rescue => e
          puts "    Could not get character box: #{e.message}"
        end
      end
    end

    puts "  Total matches: #{match_count}"

    # Extract links
    begin
      links = text_page.extract_links
      link_count = links.count
      puts "\nLinks found: #{link_count}"

      # Show link details
      link_count.times do |link_index|
        # Only show the first 5 links
        if link_index < 5
          url = links.get_url(link_index)
          range = links.get_text_range(link_index)
          link_text = text_page.get_text(range[:start_index], range[:count])

          puts "  Link #{link_index + 1}: #{url}"
          puts "    Text: #{link_text}"
        end
      end

      links.close
    rescue => e
      puts "  Could not extract links: #{e.message}"
    end

    # Clean up
    text_page.close
    Pdfium::Bindings.FPDF_ClosePage(page)
  end

  # Close the document
  pdf.close
  puts "\nPDF document closed."

rescue Pdfium::LibraryNotFoundError => e
  puts "Error: #{e.message}"
  puts "Make sure the PDFium library is installed and set PDFIUM_LIBRARY_PATH if needed."
  exit 1
rescue Pdfium::DocumentLoadError => e
  puts "Error loading document: #{e.message}"
  exit 1
rescue Pdfium::OperationError => e
  puts "Error during operation: #{e.message}"
  exit 1
end
