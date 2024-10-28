# frozen_string_literal: true

require 'json'
require 'pathname'
require 'fileutils'

# Cucumber JSON Parser
class CucumberParser
  def self.parse(json_file)
    unless File.exist?(json_file) && File.readable?(json_file)
      raise ArgumentError, "File #{json_file} does not exist or is not readable"
    end

    file_content = File.read(json_file)
    json_data = JSON.parse(file_content)
    scenario = []

    json_data.each do |feature|
      feature['elements'].each do |element|
        scenario = {
          name: element['name'],
          description: element['description'],
          steps: [],
          start_timestamp: element['start_timestamp'],
          type: element['type']
        }

        element['steps'].each do |step|
          step_data = {
            name: step['name'],
            status: step['result']['status'],
            duration: step['result']['duration']
          }
          scenario[:steps] << step_data
        end
        scenario << scenario
      end
    end
    scenario
  end
end