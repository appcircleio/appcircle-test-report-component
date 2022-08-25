require 'English'
require 'json'

class LcovParser
  def self.parse(filepath)
    unless File.exist?(filepath) && File.readable?(filepath)
      raise ArgumentError, "File #{filepath} does not exist or is not readable"
    end

    coverage = {
        reporter: 'lcov',
        coveredLines: 0,
        lineCoverage: 0,
        executableLines: 0,
        targets: [],
    }

    target = {
      name: "",
      coveredLines: 0,
      executableLines: 0,
      lineCoverage: 0,
      files: [],
    }

    target_file =
      {
        name: "",
        coveredLines: 0,
        executableLines: 0,
        lineCoverage: 0,
        functions: [],
      }

    File.readlines(filepath).each do |line|
      case line
      when /^TN:(.*)$/
        target = { name: "",
                   coveredLines: 0,
                   executableLines: 0,
                   lineCoverage: 0,
                   files: [] }
        target_file = { name: "",
                        coveredLines: 0,
                        executableLines: 0,
                        lineCoverage: 0,
                        functions: [] }
        target[:name] = Regexp.last_match(1).strip.empty? ? "No Name" : Regexp.last_match(1).strip

      when /^SF:(.+)/ # Source file
        current_filename = $LAST_MATCH_INFO[1].gsub(%r{^\./}, "")
        target_file[:name] = current_filename
      when /^LF:(\d+)/ # Line execution count
        total = $LAST_MATCH_INFO[1]
        target_file[:executableLines] = total.to_i
      when /^LH:(\d+)/ # Line execution count
        covered = $LAST_MATCH_INFO[1]
        target_file[:coveredLines] = covered.to_i
      when /^FNDA:(\d+),(.*)$/
        hit_count = $LAST_MATCH_INFO[1]
        function_name = $LAST_MATCH_INFO[2]
        executableLines = 1
        coveredLines = hit_count.to_i > 0 ? 1 : 0
        line_coverage = hit_count.to_i > 0 ? 1 : 0

        target_function = {
          name: function_name,
          coveredLines: coveredLines,
          executableLines: executableLines,
          lineCoverage: line_coverage,
        }
        target_file[:functions].push(target_function)
      when /^end_of_record$/
        target[:files] << target_file
        target_file[:lineCoverage] = target_file[:executableLines] > 0 ? target_file[:coveredLines].to_f / target_file[:executableLines].to_f : 0
        target[:executableLines] += target_file[:executableLines]
        target[:coveredLines] += target_file[:coveredLines]
        target[:lineCoverage] = target[:executableLines] > 0 ? (target[:coveredLines].to_f / target[:executableLines].to_f) : 0
        coverage[:targets] << target
        coverage[:coveredLines] += target_file[:coveredLines]
        coverage[:executableLines] += target_file[:executableLines]
      end
    end
    coverage[:lineCoverage] = coverage[:executableLines] > 0 ? coverage[:coveredLines].to_f / coverage[:executableLines].to_f : 0
    return coverage
  end
end
