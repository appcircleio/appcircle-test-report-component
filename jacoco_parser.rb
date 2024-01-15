# frozen_string_literal: true

require 'nokogiri'
require 'json'
require 'pathname'
require 'fileutils'

class JacocoParser
  def self.parse(xml, coverage_type)
    unless File.exist?(xml) && File.readable?(xml)
      raise ArgumentError, "File #{xml} does not exist or is not readable"
    end
    doc = Nokogiri::XML(File.read(xml))
    coverage = { reporter: 'jacoco', coveredLines: 0, lineCoverage: 0, targets: [], executableLines: 0 }

    return coverage if doc.xpath('//report').empty?

    report_counter = doc.xpath("//report/counter[@type='#{coverage_type}']").first
    if report_counter
      coveredLines = report_counter['covered'].to_i
      executableLines = report_counter['missed'].to_i + coveredLines
      lineCoverage = executableLines > 0 ? coveredLines.to_f / executableLines : 0
      coverage[:coveredLines] = coveredLines
      coverage[:executableLines] = executableLines
      coverage[:lineCoverage] = lineCoverage
    end

    doc.xpath('//package').each do |package|
      packageName = package['name']
      package_counter = package.xpath("counter[@type='#{coverage_type}']").first
      if package_counter
        coveredLines = package_counter['covered'].to_i
        executableLines = package_counter['missed'].to_i + coveredLines
        lineCoverage = executableLines > 0 ? coveredLines.to_f / executableLines : 0

        target = { name: packageName, coveredLines: coveredLines, executableLines: executableLines,
                   lineCoverage: lineCoverage, files: [] }

        package.xpath('class').each do |class_node|
          className = class_node['name']
          name = className.split('/').last.gsub('$', '.')
          class_counter = class_node.xpath("counter[@type='#{coverage_type}']").first
          if class_counter
            coveredLines = class_counter['covered'].to_i
            executableLines = class_counter['missed'].to_i + coveredLines
            lineCoverage = executableLines > 0 ? coveredLines.to_f / executableLines : 0
            class_file = { name: name, coveredLines: coveredLines, executableLines: executableLines,
                           lineCoverage: lineCoverage, functions: [] }

            class_node.xpath('method').each do |method|
              methodName = method['name']
              method_counter = method.xpath("counter[@type='#{coverage_type}']").first
              if method_counter
                coveredLines = method_counter['covered'].to_i
                executableLines = method_counter['missed'].to_i + coveredLines
                lineCoverage = executableLines > 0 ? coveredLines.to_f / executableLines : 0
                function = { name: methodName, coveredLines: coveredLines, executableLines: executableLines,
                             lineCoverage: lineCoverage }
                class_file[:functions] << function
              end
            end
            target[:files] << class_file
          end
        end
        coverage[:targets] << target
      end
    end
    puts "Total Coverage Percentage according to Coverage Type #{coverage_type}: #{(coverage[:lineCoverage] * 100).round(2)}%"
    coverage
  end
end