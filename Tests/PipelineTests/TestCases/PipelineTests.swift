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

protocol IntHolder: CacheableResult, Equatable, Codable, CustomStringConvertible {
    var int: Int { get }
}
extension IntHolder {
    var description: String { "\(typeName(of: self))(\(int))" }
}

struct A: IntHolder, ExpressibleByIntegerLiteral {
    let int: Int
    init(int: Int) {
        self.int = int
    }
    init(integerLiteral value: Int) {
        self.init(int: value)
    }
}


protocol IntHolderByProxy: IntHolder {
    associatedtype Proxy: IntHolder
    var proxy: Proxy { get }
    init(proxy: Proxy)
}
extension IntHolderByProxy {
    var int: Int { proxy.int }
    init(_ proxy: Proxy) {
        self.init(proxy: proxy)
    }
}

struct B: IntHolderByProxy {
    typealias Proxy = A
    let proxy: Proxy
}
struct C: IntHolderByProxy {
    typealias Proxy = B
    let proxy: Proxy
}
struct D: IntHolderByProxy {
    typealias Proxy = C
    let proxy: Proxy
}

//struct B: IntHolder {
//    let int: Int
//    init(a proxy: A) {
//        self.int = proxy.int
//    }
//}
//
//struct C: IntHolder {
//    let int: Int
//    init(b proxy: B) {
//        self.int = proxy.int
//    }
//}
//
//struct D: IntHolder {
//    let int: Int
//    init(c proxy: C) {
//        self.int = proxy.int
//    }
//}
//
//struct E: IntHolder {
//    let int: Int
//    init(d proxy: D) {
//        self.int = proxy.int
//    }
//}
//
//struct F: IntHolder {
//    let int: Int
//    init(e proxy: E) {
//        self.int = proxy.int
//    }
//}

//struct G: IntHolderByProxy {
//    typealias Proxy = F
//    let proxy: Proxy
//}

protocol ChainedIntStep: Step where Output: IntHolderByProxy, Output.Proxy == Input {

}
extension ChainedIntStep {
    func perform(input: Input) throws -> Output {
        Output.init(input)
    }
}

struct AtoB: ChainedIntStep {
    typealias Input = A
    typealias Output = B
}

struct BtoC: ChainedIntStep {
    typealias Input = B
    typealias Output = C
}

struct CtoD: ChainedIntStep {
    typealias Input = C
    typealias Output = D
//    func perform(input c: C) throws -> D {
//        D(c: c)
//    }
}
struct DtoE: ChainedIntStep {
    typealias Input = C
    typealias Output = D
//    func perform(input: Input) throws -> Output {
//        Output(c: input)
//    }
}
