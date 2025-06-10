# frozen_string_literal: true

require 'json'
require 'pathname'
require 'fileutils'

class CucumberParser
  def self.parse(json_file)
    unless File.exist?(json_file) && File.readable?(json_file)
      raise ArgumentError, "File #{json_file} does not exist or is not readable"
    end

    file_content = File.read(json_file)
    json_data = JSON.parse(file_content)
    test_suites = []

    json_data.each do |feature|
      feature['elements'].each do |element|
        count = element['steps'].size
        failures = element['steps'].count { |s| s['result']['status'] == 'failed' }
        errors = 0  
        skipped = element['steps'].count { |s| s['result']['status'] == 'skipped' }
        time = element['steps'].map { |s| (s['result']['duration'].to_f / 1_000_000_000) || 0.0 }.sum

        scenario = {
          name: element['name'],
          description: element['description'] || "",
          tests: element['steps'].map do |step| # Changed from steps to tests
            {
              name: step['name'],
              status: step['result']['status'] == 'failed' ? 'Failure' : 'Success',
              time: step['result']['duration'] # Changed from duration to time
            }
          end,
          start_timestamp: element['start_timestamp'],
          type: element['type'],
          count: count,
          failures: failures,
          errors: errors,
          skipped: skipped,
          time: time
        }

        test_suites << scenario
      end
    end
    return test_suites
  end
end