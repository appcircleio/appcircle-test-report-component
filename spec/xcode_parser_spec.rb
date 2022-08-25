# frozen_string_literal: true

require 'spec_helper'

require_relative '../xcode_parser'
describe XcodeParser do
  describe '#parse' do
    context 'when given a valid coverage file' do
      it 'parses xml file' do
        test_path = 'spec/fixtures/test.xcresult'
        repo_path = 'spec/fixtures/repo'
        output_path = 'tmp'
        parser = XcodeParser.new(test_path, repo_path, output_path)
        result = parser.parse
        coverage = result[:coverage]
        expect(coverage['coveredLines']).to eq(148)
        expect((coverage['lineCoverage'] * 100).to_i).to eq(91)
        expect(coverage['executableLines']).to eq(161)
        expect(coverage['targets'].count).to eq(5)

        test_suites = result[:test_suites]
        expect(test_suites[0][:count]).to eq(2)
        expect(test_suites[0][:failures]).to eq(0)
        expect(test_suites[0][:errors]).to eq(0)
        expect(test_suites[0][:device_name]).to eq('iPhone 8 Plus')
      end
    end

    context 'when given failed test file' do
      it 'raise error' do
        result = {}
        test_path = 'spec/fixtures/failed.xcresult'
        repo_path = '/Users/mustafa/Desktop/NSISTANBUL2022'
        output_path = 'tmp'
        parser = XcodeParser.new(test_path, repo_path, output_path)
        result = parser.parse
        coverage = result[:coverage]
        expect(coverage['coveredLines']).to eq(134)
        expect((coverage['lineCoverage'] * 100).to_i).to eq(81)
        expect(coverage['executableLines']).to eq(165)
        expect(coverage['targets'].count).to eq(4)

        test_suites = result[:test_suites]
        expect(test_suites[0][:count]).to eq(4)
        expect(test_suites[0][:failures]).to eq(1)
        expect(test_suites[0][:errors]).to eq(0)
        expect(test_suites[0][:device_name]).to eq('iPod touch (7th generation)')
      end
    end

    context 'when given missing coverage file' do
      it 'raise error' do
        result = {}
        test_path = 'spec/fixtures/output'
        repo_path = 'spec/fixtures/repo'
        output_path = 'tmp'
        parser = XcodeParser.new(test_path, repo_path, output_path)
        expect do
          result = parser.parse
        end.to raise_error(ArgumentError, /does not exist/)
      end
    end
  end
end
