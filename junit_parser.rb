# frozen_string_literal: true

require 'nokogiri'
require 'json'
require 'pathname'
require 'fileutils'

# parse JUnit Test results
class JunitParser
  def self.parse(xml)
    unless File.exist?(xml) && File.readable?(xml)
      raise ArgumentError, "File #{xml} does not exist or is not readable"
    end

    doc = Nokogiri::XML(File.read(xml))
    test_suites = []

    doc.xpath('//testsuite').each do |test_suite|
      device = test_suite.at_xpath('properties/property[@name="device"]')
      device_name = device.nil? ? 'Unknown' : device['value']
      suite = {
        name: test_suite['name'],
        path: File.dirname(xml),
        filename: File.basename(xml),
        tests: [],
        count: test_suite['tests'].to_i,
        failures: test_suite['failures'].to_i,
        errors: test_suite['errors'].to_i,
        skipped: test_suite['skipped'].to_i,
        time: test_suite['time'].to_f,
        device_name: device_name
      }

      test_suite.xpath('testcase').each do |test_case|
        suite[:tests] << {
          name: test_case['name'],
          time: test_case['time'].to_f,
          classname: test_case['classname'],
          failure: test_case.at_xpath('failure') ? test_case.at_xpath('failure').text : nil,
          error: test_case.at_xpath('error') ? test_case.at_xpath('error').text : nil,
          skipped: test_case.at_xpath('skipped') ? test_case.at_xpath('skipped').text : nil
        }
      end
      test_suites << suite
    end
    test_suites
  end
end
