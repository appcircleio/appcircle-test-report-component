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

  @@xcode_version = nil
  def get_xcode_version
    @@xcode_version ||= begin
      output = execute_cmd("xcodebuild -version")
      output.match(/Xcode (\d+(\.\d+)?)/)[1].to_f
    end
  end

  def get_xcrun_command(cmd_func, id: nil, filename: nil, output_path: nil)
    cmd = "xcrun xcresulttool #{cmd_func}"
    cmd += " object --legacy"  if get_xcode_version >= 16.0
    cmd += " --format json" if cmd_func == "get"
    cmd += " --path #{@test_path}"
    cmd += " --id #{id}" if id
    cmd += " --output-path '#{output_path}' --type file" if output_path
    cmd
  end

  def get_object(id = nil)
    cmd = get_xcrun_command("get", id: id)
    raw_result = execute_cmd(cmd)
    JSON.parse(raw_result)
  end

  def extract_attachment(filename, id)
    attachments_path = (Pathname.new @output_path).join('test_attachments')
    FileUtils.mkdir_p(attachments_path) unless Dir.exist?(attachments_path)
    output_path = File.join(attachments_path, filename)
    puts "Exporting attachment #{filename}"
    cmd = get_xcrun_command("export", id: id, output_path: output_path)
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

    testable_summaries = tests.dig('summaries', '_values', 0, 'testableSummaries', '_values')
    return [] unless testable_summaries
    testable_summaries.each do |target|
      target_name = target['targetName']['_value']

      # if the test target failed to launch at all, get first failure message
      unless target['tests']
        failure_summary = target.dig('failureSummaries', '_values', 0, 'message', '_value')
        test_suites << { name: target_name, error: failure_summary || 'Unknown failure' }
        next
      end

      test_classes = target['tests']['_values']

      # else process the test classes in each target
      # first two levels are just summaries, so skip those
      class_values = test_classes.dig(0, 'subtests', '_values', 0, 'subtests', '_values')
      next unless class_values
      class_values.each do |test_class|
        suite = { name: "#{target_name}.#{test_class['name']['_value']}", tests: [], device_name: device_name }
        # process the tests in each test class
        tests = test_class.dig('subtests', '_values')

        if tests
          tests.each do |test|
            duration = 0
            duration = test['duration']['_value'] if test['duration']
            testcase = { name: test['name']['_value'], time: duration.to_f, attachments: [],
                         status: test['testStatus']['_value'] }
            if test['testStatus']['_value'] == 'Failure'
              failures = get_object(test.dig('summaryRef', 'id', '_value')).dig('failureSummaries', '_values') || []
              message = failures.map { |failure| failure.dig('message', '_value') }.compact.join("\n")
              location = failures.find { |failure| failure.dig('fileName', '_value') && failure['fileName']['_value'] != '<unknown>' }

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
            summary_id = test.dig('summaryRef', 'id', '_value')
            if summary_id
              testsummary = get_object(summary_id)
              activities = testsummary.dig('activitySummaries', '_values') || []
              activities.each do |activity|
                attachments = activity.dig('attachments', '_values') || []
                attachments.each do |attachment|
                  filename = attachment.dig('filename', '_value')
                  attachment_id = attachment.dig('payloadRef', 'id', '_value')
                  next unless filename && attachment_id
                  extract_attachment(filename, attachment_id)
                  testcase[:attachments] << { id: attachment_id, name: filename }
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
        suite[:time] = suite[:tests].sum { |testcase| testcase[:time]}
        suite[:skipped] = suite[:tests].count {  |testcase| testcase[:status] == "Skipped" }
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
