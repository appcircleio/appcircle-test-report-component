# frozen_string_literal: true

require 'json'
require_relative 'junit_parser'

# Parse test results
class TestParser
  def initialize(path)
    @path = path
  end

  def find_junits
    test_suites = []
    @path.split(':').each do |directory|
      puts "Searching #{directory} for JUnit test results..."
      Dir.glob("#{directory}/**/*.xml").each do |xml|
        File.open(xml, 'r') do |f|
          doc = Nokogiri::XML(f)
          if doc.at_xpath('//testcase')
            puts "Found JUnit testcase in #{xml}"
            test_suites << JunitParser.parse(xml)
          end
        end
      end
    end
    test_suites.flatten(1)
  end

  def parse
    find_junits
  end
end
