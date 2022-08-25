# frozen_string_literal: true

require 'nokogiri'
require 'json'
require 'pathname'
require 'fileutils'

class JacocoParser
  def self.parse(xml)
    unless File.exist?(xml) && File.readable?(xml)
      raise ArgumentError, "File #{xml} does not exist or is not readable"
    end
    doc = Nokogiri::XML(File.read(xml))
    coverage = { reporter: 'jacoco', coveredLines: 0, lineCoverage: 0, targets: [], executableLines: 0 }
    if doc.xpath('//report').empty?
      return coverage
    end
    coveredLines = doc.xpath('//report/counter[@type="LINE"]').first['covered'].to_i
    executableLines = doc.xpath('//report/counter[@type="LINE"]').first['missed'].to_i + coveredLines
    lineCoverage = coveredLines.to_f / executableLines
    coverage[:coveredLines] = coveredLines
    coverage[:executableLines] = executableLines
    coverage[:lineCoverage] = lineCoverage

    doc.xpath('//package').each do |package|
      packageName = package['name']
      coveredLines = package.xpath('counter[@type="LINE"]').first['covered'].to_i
      executableLines = package.xpath('counter[@type="LINE"]').first['missed'].to_i + coveredLines
      lineCoverage = coveredLines.to_f / executableLines

      target = { name: packageName, coveredLines: coveredLines, executableLines: executableLines,
                 lineCoverage: lineCoverage, files: [] }
      package.xpath('class').each do |class_node|
        className = class_node['name']
        name = className.split('/').last.gsub('$', '.')
        coveredLines = class_node.xpath('counter[@type="LINE"]').first['covered'].to_i
        executableLines = class_node.xpath('counter[@type="LINE"]').first['missed'].to_i + coveredLines
        lineCoverage = coveredLines.to_f / executableLines
        class_file = { name: name, coveredLines: coveredLines, executableLines: executableLines,
                       lineCoverage: lineCoverage, functions: [] }
        class_node.xpath('method').each do |line|
          methodName = line['name']
          coveredLines = line.xpath('counter[@type="LINE"]').first['covered'].to_i
          executableLines = line.xpath('counter[@type="LINE"]').first['missed'].to_i + coveredLines
          lineCoverage = coveredLines.to_f / executableLines
          function = { name: methodName, coveredLines: coveredLines, executableLines: executableLines,
                       lineCoverage: lineCoverage }
          class_file[:functions] << function
        end
        target[:files] << class_file
      end
      coverage[:targets] << target
    end
    coverage
  end
end
