# Appcircle Test Report Component

This component parses test and coverage results to single JSON file. This component currently supports following test and coverage formats

## Test Format

- Xcode 13+ `.xctest`
- JUnit `.xml`

## Coverage Format

- JaCoCo `.xml`
- Cobertura `.xml`
- Lcov `lcov.info` 

**Note:** Lcov is a simple file format for the code coverage. If your testting framework supports, it is better to create JaCoCo or Cobertura files.

## Required Inputs

- `AC_TEST_RESULT_PATH`: Test result path. This directory and subdirectories will be searched for compatible test files. This envıronment variable is automatically set if you use Appcircle's test component

- `AC_COVERAGE_RESULT_PATH`: Coverage result path. This environment variable is automatically set for iOS projects. For React Native and Flutter projects, you need to enter the coverage path.

## Output

- `AC_TEST_REPORT_JSON_PATH`: Component creates a single JSON which contains the test and coverage results.

# Development

If you want to add new parsers, you can follow the convention of other parsers and include them in either `test_parser.rb` or `coverage_parser.rb`

# Test and code coverage
This component can be tested with following command

```
rspec --format documentation
```
