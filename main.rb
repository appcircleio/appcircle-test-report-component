# frozen_string_literal: true

require 'json'
require_relative 'test_parser'
require_relative 'coverage_parser'
require_relative 'xcode_parser'

repo_path = ENV['AC_REPOSITORY_DIR']
platform = ENV['AC_PLATFORM_TYPE']
output_path = ENV['AC_OUTPUT_DIR']
test_path = ENV['AC_TEST_RESULT_PATH']
coverage_path = ENV['AC_COVERAGE_RESULT_PATH']

puts "Platform #{platform}"
report = {}

if platform == 'ObjectiveCSwift'
  parser = XcodeParser.new(test_path, repo_path, output_path)
  report = parser.parse
else
  test_parser = TestParser.new(test_path)
  test_suites = test_parser.parse
  coverage_parser = CoverageParser.new(coverage_path)
  coverage = coverage_parser.parse
  report = { coverage: coverage, test_suites: test_suites }
end

File.open("#{output_path}/test_results.json", 'w') do |f|
  f.write(JSON.pretty_generate(report))
end

File.open(ENV['AC_ENV_FILE_PATH'], 'a') { |f|
  f.puts "AC_TEST_REPORT_JSON_PATH=#{output_path}/test_results.json"
}
