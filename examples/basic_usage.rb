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
  width, height = pdf.dimensions

  puts "Document information:"
  puts "- Page count: #{page_count}"
  puts "- Dimensions (first page): #{width.round(2)} x #{height.round(2)} points"

  # Get annotations
  annotations = pdf.annotations
  puts "\nAnnotations:"
  puts "- Total annotations: #{annotations.size}"

  # Print annotations by page
  page_count.times do |page_index|
    page_annotations = pdf.annotations_by_page(page_index)
    puts "\nPage #{page_index + 1} annotations (#{page_annotations.size}):"

    page_annotations.each_with_index do |annotation, index|
      puts "  #{index + 1}. Type: #{annotation[:subtype]}"
      puts "     Position: left=#{annotation[:rect][:left].round(2)}, " \
           "bottom=#{annotation[:rect][:bottom].round(2)}, " \
           "right=#{annotation[:rect][:right].round(2)}, " \
           "top=#{annotation[:rect][:top].round(2)}"
      puts "     Contents: #{annotation[:contents]}" unless annotation[:contents].empty?
    end
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
