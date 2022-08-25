# frozen_string_literal: true

require 'spec_helper'
require_relative '../cobertura_parser'
describe CoberturaParser do
  describe '#parse' do
    context 'when given a valid coverage file' do
      it 'parses xml file' do
        result = CoberturaParser.parse('spec/fixtures/cobertura.xml')
        expect(result[:coveredLines]).to eq(88)
        expect((result[:lineCoverage] * 100).to_i).to eq(100)
        expect(result[:executableLines]).to eq(88)
        expect(result[:targets].count).to eq(2)
      end
    end

    context 'when given a empty coverage file' do
      it 'parses xml file' do
        result = CoberturaParser.parse('spec/fixtures/empty-cobertura.xml')
        expect(result[:coveredLines]).to eq(0)
        expect((result[:lineCoverage] * 100).to_i).to eq(0)
        expect(result[:executableLines]).to eq(2)
        expect(result[:targets].count).to eq(1)
      end
    end

    context 'when given a coverage file with methods' do
      it 'parses xml file' do
        result = CoberturaParser.parse('spec/fixtures/cobertura2.xml')
        expect(result[:coveredLines]).to eq(11)
        expect((result[:lineCoverage] * 100).to_i).to eq(91)
        expect(result[:executableLines]).to eq(12)
        expect(result[:targets].count).to eq(2)
      end
    end


    context 'when given an invalid coverage file' do
      it 'covered lines is 0' do
        result = {}
        expect { result = CoberturaParser.parse('spec/fixtures/invalid_file.txt') }.not_to raise_error
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
          result = CoberturaParser.parse('spec/fixtures/wrong_file')
        end.to raise_error(ArgumentError, /does not exist/)
      end
    end
  end
end
