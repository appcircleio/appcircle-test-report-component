# frozen_string_literal: true

require 'nokogiri'
require 'json'
require 'pathname'
require 'fileutils'

class CoberturaParser

    def self.parse(xml)
      unless File.exist?(xml) && File.readable?(xml)
        raise ArgumentError, "File #{xml} does not exist or is not readable"
      end
  
        doc = Nokogiri::XML(File.read(xml))
        coveredLines = 0
        executableLines = 0
        lineCoverage = 0
        coverage = { reporter: 'cobertura', coveredLines: coveredLines, lineCoverage: lineCoverage, targets: [],
                     executableLines: executableLines }
      
        doc.xpath('//package').each do |package|
          packageName = package['name']
          coveredLines = 0
          executableLines = 0
          lineCoverage = 0
      
          target = { name: packageName, coveredLines: coveredLines, executableLines: executableLines,
                     lineCoverage: lineCoverage, files: [] }
          package.xpath('classes/class').each do |class_node|
            name = class_node['filename']
            executableLines = class_node.xpath('lines/line').count
            coveredLines = class_node.xpath('lines/line').count { |node| node[:hits].to_i.positive? }
      
            lineCoverage = if executableLines.positive?
                             coveredLines.to_f / executableLines
                           else
                             0
                           end
            
            class_file = { name: name, coveredLines: coveredLines, executableLines: executableLines,
                           lineCoverage: lineCoverage, functions: [] }
            target[:coveredLines] += coveredLines
            target[:executableLines] += executableLines
            target[:lineCoverage] = target[:coveredLines].to_f / target[:executableLines].to_f
      
            class_node.xpath('methods/method').each do |line|
              executableLines = line.xpath('lines/line').count
              coveredLines = line.xpath('lines/line').count { |node| node[:hits].to_i.positive? }
              lineCoverage = if executableLines.positive?
                               coveredLines.to_f / executableLines
                             else
                               0
                             end
      
              methodName = line['name']
                    
              function = { name: methodName, coveredLines: coveredLines, executableLines: executableLines,
                           lineCoverage: lineCoverage }
              class_file[:functions] << function
            end
            target[:files] << class_file
          end
          coverage[:targets] << target
          coverage[:coveredLines] += target[:coveredLines]
          coverage[:executableLines] += target[:executableLines]
        end
        coverage[:lineCoverage] = if (coverage[:coveredLines]).positive?
                                    coverage[:coveredLines].to_f / coverage[:executableLines]
                                  else
                                    0
                                  end
        coverage
      end

end
