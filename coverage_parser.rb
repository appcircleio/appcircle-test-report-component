# frozen_string_literal: true

require 'nokogiri'
require 'json'
require 'pathname'
require 'fileutils'

require_relative 'cobertura_parser'
require_relative 'jacoco_parser'
require_relative 'lcov_parser'

# Parse coverage results
class CoverageParser
  def initialize(path)
    @path = path
  end

  # Detect type of file
  def parse_xml(xml)
    doc = Nokogiri::XML(File.read(xml))
    internal_subset = doc.internal_subset
    if internal_subset.external_id =~ /JACOCO/
        puts "Parsing JaCoCo report #{xml}"
        JacocoParser.parse(xml)
    elsif internal_subset.system_id =~ /cobertura/
        puts "Parsing Cobetura report #{xml}"
        CoberturaParser.parse(xml)
    end


  end
  def parse_files
    result = []
    @path.split(':').each do |directory|
      puts "Searching #{directory} for coverage files..."
      Dir.glob("#{directory}/**/*.{xml,info}").each do |file|
        extension = File.extname(file)
        case extension
        when '.xml'
           result << parse_xml(file)
        when '.info'
            puts "Parsing Lcov.info report #{file}"
           result << LcovParser.parse(file)
        end
      end
    end
    result.flatten(1)
  end

  def parse
    parse_files
  end
end