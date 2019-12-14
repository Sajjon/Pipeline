import XCTest

import PipelineTests

var tests = [XCTestCaseEntry]()
tests += VanillaTests.allTests()
tests += PipelineTests.allTests()
XCTMain(tests)
