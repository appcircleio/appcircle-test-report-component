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
  if test_path.nil? || test_path.empty?
    puts 'No test path given'
  else
    begin
      parser = XcodeParser.new(test_path, repo_path, output_path)
      report = parser.parse  
    rescue StandardError
      # It means User gave JUnit XML
      test_parser = TestParser.new(test_path)
      test_suites = test_parser.parse
      report = { coverage: {}, test_suites: test_suites }
    end

  end
else
  test_suites = {}
  coverage = {}
  if test_path.nil? || test_path.empty?
    puts 'No test path given'
  else
    test_parser = TestParser.new(test_path)
    test_suites = test_parser.parse
  end
  if coverage_path.nil? || coverage_path.empty?
    puts 'No coverage path given'
  else
    coverage_parser = CoverageParser.new(coverage_path)
    coverage = coverage_parser.parse
  end
  report = { coverage: coverage, test_suites: test_suites }
end

count = 0
failures = 0
errors = 0
skipped = 0
time = 0

if report[:test_suites]&.count&.positive?
  count = report[:test_suites].reduce(0) { |t, suite| t + suite[:count] }
  failures = report[:test_suites].reduce(0) { |t, suite| t + suite[:failures] }
  errors = report[:test_suites].reduce(0) { |t, suite| t + suite[:errors] }
  skipped = report[:test_suites].reduce(0) { |t, suite| t + suite[:skipped] }
  time = report[:test_suites].reduce(0) { |t, suite| t + suite[:time] }
end
final_report = { coverage: report[:coverage],
                 test_suites: { count: count, failures: failures, errors: errors, skipped:skipped, time:time, suites: report[:test_suites] } }

File.open("#{output_path}/test_results.json", 'w') do |f|
  f.write(JSON.pretty_generate(final_report))
end

File.open(ENV['AC_ENV_FILE_PATH'], 'a') do |f|
  f.puts "AC_TEST_REPORT_JSON_PATH=#{output_path}/test_results.json"
end
