import XCTest
@testable import Pipeline

final class PipelineTests: XCTestCase {

    func testTwoSteps() throws {

        let pipeline = Pipeline<A, C> {
            AtoB()
            BtoC()
        }
        let output = try pipeline.perform(input: 5)
        XCTAssertEqual(output, C(B(5)))
    }


    static var allTests = [
        ("testTwoSteps", testTwoSteps),
    ]
}

struct A: Equatable, Codable, ExpressibleByIntegerLiteral {
    let int: Int
    init(_ int: Int) {
        self.int = int
    }
    init(integerLiteral int: Int) {
        self.int = int
    }
}
struct B: Equatable, Codable {
    let a: A
    init(_ a: A) { self.a = a }
}
struct C: Equatable, Codable {
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

extension A {
    static var irrelevant: Self {
        Self(Int.irrelevant)
    }
}

extension Int {
    static let irrelevant = 0
}
