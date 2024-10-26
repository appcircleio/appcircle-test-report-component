# frozen_string_literal: true

require 'json'
require_relative 'junit_parser'
require_relative 'cucumber_parser'

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

  def find_cucumber_json
    test_suites = []
    @path.split(':').each do |directory|
      puts "Searching #{directory} for Cucumber JSON test results..."
      Dir.glob("#{directory}/**/*.json").each do |json_file|
        if File.read(json_file).include?('"elements"')
          puts "Found Cucumber JSON test results in #{json_file}"
          test_suites << CucumberParser.parse(json_file)
        end
      end
    end
    test_suites.flatten(1)
  end

  def parse
    junit_results = find_junits
    cucumber_results = find_cucumber_json

    { junit: junit_results, cucumber: cucumber_results }
  end
end
