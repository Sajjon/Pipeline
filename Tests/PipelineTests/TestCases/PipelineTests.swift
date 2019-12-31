import XCTest
@testable import Pipeline
@testable import Core

final class PipelineTests: XCTestCase {

    func testTwoSteps() throws {

        let pipeline = Pipeline<A, C> {
            AtoB()
            BtoC()
        }
        XCTAssertEqual(pipeline.description, "AtoB -> BtoC")
        let output = try pipeline.perform(input: A(int: 5))
        XCTAssertEqual(output, C(B(A(int: 5))))
    }

    func testThreeSteps() throws {

        let pipeline = Pipeline<A, D> {
            AtoB()
            BtoC()
            CtoD()
        }
        XCTAssertEqual(pipeline.description, "AtoB -> BtoC -> CtoD")
        let output = try pipeline.perform(input: A(int: 7))
        XCTAssertEqual(output, D(C(B(A(int: 7)))))
    }

    static var allTests = [
        ("testTwoSteps", testTwoSteps),
        ("testThreeSteps", testThreeSteps),
    ]
}
