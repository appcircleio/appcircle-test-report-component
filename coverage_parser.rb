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
    puts("Checking #{xml}")
    doc = Nokogiri::XML(File.read(xml))
    internal_subset = doc.internal_subset
    if defined?(internal_subset.external_id) && internal_subset.external_id =~ /JACOCO/
      puts "Parsing JaCoCo report #{xml}"
      JacocoParser.parse(xml)
    elsif defined?(internal_subset.system_id) && internal_subset.system_id =~ /cobertura/
      puts "Parsing Cobetura report #{xml}"
      CoberturaParser.parse(xml)
    end
  end

  def parse
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

    coveredLines = 0
    executableLines = 0
    lineCoverage = 0
    targets = []
    result = result.compact
    unless result.empty?
      targets = result.map { |item| item[:targets] }.flatten
      coveredLines = result.reduce(0) { |sum, obj| sum + obj[:coveredLines] }
      executableLines = result.reduce(0) { |sum, obj| sum + obj[:executableLines] }
      lineCoverage = coveredLines.to_f / executableLines
    end

    {
      targets: targets,
      coveredLines: coveredLines,
      executableLines: executableLines,
      lineCoverage: lineCoverage
    }
  end
end
