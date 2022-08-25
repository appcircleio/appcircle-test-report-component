# frozen_string_literal: true

require 'English'
require 'json'
require 'pathname'
require 'fileutils'

class XcodeParser
  def initialize(test_path, repo_path, output_path)
    @test_path = test_path
    @repo_path = repo_path
    @output_path = output_path
  end

  def execute_cmd(cmd)
    output = `#{cmd}`
    raise "Failed to execute - #{cmd}" unless $CHILD_STATUS.success?

    output
  end

  def get_object(id = nil)
    cmd = "xcrun xcresulttool get --format json --path #{@test_path}"
    cmd += " --id #{id}" if id
    raw_result = execute_cmd(cmd)
    JSON.parse raw_result
  end

  def extract_attachment(filename, id)
    attachments_path = (Pathname.new @output_path).join('test_attachments')
    FileUtils.mkdir_p(attachments_path) unless Dir.exist?(attachments_path)
    output_path = File.join(attachments_path, filename)
    puts "Exporting attachment #{filename}"
    cmd = "xcrun xcresulttool export --path #{@test_path} --id '#{id}' --output-path '#{output_path}' --type file"
    execute_cmd(cmd)
  end

  def parse_actions(action)
    device_name = action.dig('runDestination', 'displayName', '_value')
    puts "Test Device: #{device_name}"

    tests_ref = action.dig('actionResult', 'testsRef', 'id', '_value')
    return nil if tests_ref.nil?

    tests = get_object tests_ref

    # transform to a dictionary that mimics the output structure

    test_suites = []

    tests['summaries']['_values'][0]['testableSummaries']['_values'].each do |target|
      target_name = target['targetName']['_value']

      # if the test target failed to launch at all, get first failure message
      unless target['tests']
        failure_summary = target['failureSummaries']['_values'][0]
        test_suites << { name: target_name, error: failure_summary['message']['_value'] }
        next
      end

      test_classes = target['tests']['_values']

      # else process the test classes in each target
      # first two levels are just summaries, so skip those
      test_classes[0]['subtests']['_values'][0]['subtests']['_values'].each do |test_class|
        suite = { name: "#{target_name}.#{test_class['name']['_value']}", tests: [], device_name: device_name }
        # process the tests in each test class
        tests = test_class.dig('subtests', '_values')

        if tests
          tests.each do |test|
            duration = 0
            duration = test['duration']['_value'] if test['duration']
            testcase = { name: test['name']['_value'], time: duration, attachments: [],
                         status: test['testStatus']['_value'] }
            if test['testStatus']['_value'] == 'Failure'
              failures = get_object(test['summaryRef']['id']['_value'])['failureSummaries']['_values']

              message = failures.map { |failure| failure['message']['_value'] }.join("\n")
              location = failures.reject { |failure| failure['fileName']['_value'] == '<unknown>' }.first

              if location
                testcase[:failure] = message
                filename = location['fileName']['_value']
                begin
                  relative_path = Pathname.new(filename.to_s).relative_path_from(@repo_path).to_s
                rescue StandardError
                  relative_path = filename
                end
                testcase[:failure_location] = "#{relative_path}:#{location['lineNumber']['_value']}"
              else
                testcase[:error] = message
              end
            end

            puts "Extracting Artifacts for #{testcase[:name]}"
            if test['summaryRef'] && test['summaryRef']['id']
              testsummary = get_object(test['summaryRef']['id']['_value'])

              if testsummary['activitySummaries'] && testsummary['activitySummaries']['_values']
                testsummary['activitySummaries']['_values'].each do |activity|
                  next unless activity['attachments'] && activity['attachments']['_values']

                  activity['attachments']['_values'].each do |attachment|
                    attachment_filename = attachment['filename']['_value']
                    attachment_id = attachment['payloadRef']['id']['_value']
                    extract_attachment(attachment_filename, attachment_id)
                    testcase[:attachments] << { id: attachment_id, name: attachment_filename }
                  end
                end
              end
            end

            suite[:tests] << testcase
          end
        else
          # consider a test class without tests to be an error
          # there's no good reason to have an empty test class, and it can occur as an error
          suite[:tests] << { name: 'Missing tests', time: 0, error: 'No test results found' }
        end

        suite[:count] = suite[:tests].size
        suite[:failures] = suite[:tests].count { |testcase| testcase[:failure] }
        suite[:errors] = suite[:tests].count { |testcase| testcase[:error] }
        test_suites << suite
      end
    end
    test_suites
  end

  def parse
    info_plist = (Pathname.new @test_path).join('Info.plist')

    unless File.exist?(info_plist) && File.readable?(info_plist)
      raise ArgumentError, "File #{info_plist} does not exist or is not readable"
    end

    results = get_object

    test_suites = results['actions']['_values']
                  .flat_map { |action| parse_actions(action) }
                  .compact
    begin
      coverage = JSON.parse `xcrun xccov view --report --json #{@test_path}`
    rescue StandardError
      coverage = {}
    end
    { coverage: coverage, test_suites: test_suites }
  end
end
