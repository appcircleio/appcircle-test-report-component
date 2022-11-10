# frozen_string_literal: true
require 'spec_helper'

require_relative '../junit_parser'
describe JunitParser do
  describe '#parse' do
    context 'when given a valid coverage file' do
      it 'parses xml file' do
        result = JunitParser.parse('spec/fixtures/junit.xml')
        expect(result.count).to eq(1)
        expect(result[0][:count]).to eq(6)
        expect(result[0][:failures]).to eq(0)
        expect(result[0][:errors]).to eq(0)
        expect(result[0][:skipped]).to eq(0)
        expect(result[0][:time]).to eq(2.857)
        expect(result[0][:device_name]).to eq('nexusOneApi30')
      end
    end

    context 'when given an invalid coverage file' do
      it 'covered lines is 0' do
        result = {}
        expect { result = JunitParser.parse('spec/fixtures/invalid_file.txt') }.not_to raise_error
        expect(result.count).to eq(0)
      end
    end

    context 'when given missing coverage file' do
      it 'raise error' do
        result = {}
        expect do
          result = JunitParser.parse('spec/fixtures/wrong_file')
        end.to raise_error(ArgumentError, /does not exist/)
      end
    end
  end
end
