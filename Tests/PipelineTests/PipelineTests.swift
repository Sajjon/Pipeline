import XCTest
@testable import Pipeline

final class PipelineTests: XCTestCase {

    func testTwoSteps() throws {

        let pipeline = Pipeline<C> {
            AtoB()
            BtoC()
        }
        let output = try pipeline.perform(input: A(5))
        XCTAssertEqual(output, C(B(A(5))))
    }


    static var allTests = [
        ("testTwoSteps", testTwoSteps),
    ]
}

struct A: Equatable {
    let int: Int
    init(_ int: Int) {
        self.int = int
    }
}
struct B: Equatable {
    let a: A
    init(_ a: A) { self.a = a }
}
struct C: Equatable {
    let b: B
    init(_ b: B) { self.b = b }
}

struct AtoB: Step {
    func perform(input a: A) throws -> B {
        B(a)
    }
}
struct BtoC: Step {
    func perform(input b: B) throws -> C {
        C(b)
    }
}
