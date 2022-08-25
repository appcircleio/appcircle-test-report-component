# frozen_string_literal: true
require 'spec_helper'

require_relative '../lcov_parser'
describe LcovParser do
  describe '#parse' do
    context 'when given a valid lcov file' do
      it 'parses lcov file' do
        result = LcovParser.parse('spec/fixtures/lcov.info')
        expect(result[:coveredLines]).to eq(11)
        expect((result[:lineCoverage] * 100).to_i).to eq(91)
        expect(result[:executableLines]).to eq(12)
        expect(result[:targets].count).to eq(4)
      end
    end

    context 'when given an invalid lcov file' do
      it 'covered lines is 0' do
        result = {}
        expect { result = LcovParser.parse('spec/fixtures/invalid_file.txt') }.not_to raise_error
        expect(result[:coveredLines]).to eq(0)
        expect(result[:lineCoverage]).to eq(0)
        expect(result[:executableLines]).to eq(0)
        expect(result[:targets].count).to eq(0)
      end
    end

    context 'when given missing lcov file' do
      it 'raise error' do
        result = {}
        expect do
          result = LcovParser.parse('spec/fixtures/wrong_file')
        end.to raise_error(ArgumentError, /does not exist/)
      end
    end
  end
end
