import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(VanillaTests.allTests),
        testCase(PipelineTests.allTests),
    ]
}
#endif
