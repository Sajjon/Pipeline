import XCTest
@testable import Pipeline

final class PipelineTests: XCTestCase {

    func testTwoSteps() throws {

        let pipeline = Pipeline<C> {
            AtoB()
            BtoC()
        }
        XCTAssertEqual(pipeline.description, "AtoB -> BtoC")
        let output = try pipeline.perform(input: A(int: 5))
        XCTAssertEqual(output, C(b: B(a: A(int: 5))))
    }

    func testThreeSteps() throws {

        let pipeline = Pipeline<D> {
            AtoB()
            BtoC()
            CtoD()
        }
        XCTAssertEqual(pipeline.description, "AtoB -> BtoC -> CtoD")
        let output = try pipeline.perform(input: A(int: 7))
        XCTAssertEqual(output, D(c: C(b: B(a: A(int: 7)))))
    }

    static var allTests = [
        ("testTwoSteps", testTwoSteps),
        ("testThreeSteps", testThreeSteps),
    ]
}

struct A: Equatable, Codable, CustomStringConvertible {
    let int: Int
    var description: String { "A(\(int))" }
}
struct B: Equatable, Codable, CustomStringConvertible {
    let a: A
    var description: String { "B(\(a))" }
}
struct C: Equatable, Codable, CustomStringConvertible {
    let b: B
    var description: String { "C(\(b))" }
}
struct D: Equatable, Codable, CustomStringConvertible {
    let c: C
    var description: String { "D(\(c))" }
}

struct AtoB: Step {
    func perform(input a: A) throws -> B {
        B(a: a)
    }
}
struct BtoC: Step {
    func perform(input b: B) throws -> C {
        C(b: b)
    }
}
struct CtoD: Step {
    func perform(input c: C) throws -> D {
        D(c: c)
    }
}
