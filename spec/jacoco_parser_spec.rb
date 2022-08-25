# frozen_string_literal: true
require 'spec_helper'

require_relative '../jacoco_parser'
describe JacocoParser do
  describe '#parse' do
    context 'when given a valid coverage file' do
      it 'parses xml file' do
        result = JacocoParser.parse('spec/fixtures/jacoco.xml')
        expect(result[:coveredLines]).to eq(51)
        expect((result[:lineCoverage] * 100).to_i).to eq(98)
        expect(result[:executableLines]).to eq(52)
        expect(result[:targets].count).to eq(1)
      end
    end

    context 'when given an invalid coverage file' do
      it 'covered lines is 0' do
        result = {}
        expect { result = JacocoParser.parse('spec/fixtures/invalid_file.txt') }.not_to raise_error
        expect(result[:coveredLines]).to eq(0)
        expect(result[:lineCoverage]).to eq(0)
        expect(result[:executableLines]).to eq(0)
        expect(result[:targets].count).to eq(0)
      end
    end

    context 'when given missing coverage file' do
      it 'raise error' do
        result = {}
        expect do
          result = JacocoParser.parse('spec/fixtures/wrong_file')
        end.to raise_error(ArgumentError, /does not exist/)
    end
    end
  end
end
