//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2019-12-14.
//

import XCTest
@testable import Pipeline

enum StartStep: Int, Equatable, Comparable {
    case stepA, stepB, stepC, stepD, stepE, stepF, stepG, stepH, stepI, stepJ
}

extension RawRepresentable where RawValue: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < lhs.rawValue
    }
}

final class CachedFlow<Input, Output> {

    private let cacher: Cacher
    internal private(set) var stepsTakenInLastFlow = 0

    init(cacher: Cacher = .init()) {
        self.cacher = cacher
    }

    func flowOf<StepA, StepB, StepC>(
        fileName potentiallyUntrimmedFileName: String,
        input: Input,
        startAt maybeStartStep: StartStep? = nil,
        _ stepA: StepA,
        _ stepB: StepB,
        _ stepC: StepC
    ) throws -> Output
        where
        StepA: Step,
        StepB: Step,
        StepC: Step,
        StepA.Output: Codable,
        StepB.Output: Codable,
        StepC.Output: Codable,
        Input == StepA.Input,
        Output == StepC.Output,
        StepA.Output == StepB.Input,
        StepB.Output == StepC.Input
    {
        defer { stepsTakenInLastFlow = 0 }

        let startStep: StartStep = maybeStartStep ?? .stepC
        let folderName = String(potentiallyUntrimmedFileName.suffix(2)) == "()" ? String(potentiallyUntrimmedFileName.dropLast(2)) : potentiallyUntrimmedFileName

        func fileNameBasedOnType<T>(of _: T.Type) -> String {
            folderName + typeName(of: T.self)
        }

        func loadCached<S>(step: S) -> S.Output? where S: Step, S.Output: Codable {
            let fileName = fileNameBasedOnType(of: S.Output.self)
            return try? cacher.load(fileName: fileName)
        }

        func cache<ToCache>(_ makeCachable: @autoclosure () throws -> ToCache) throws -> ToCache where ToCache: Codable {
            defer { stepsTakenInLastFlow += 1 }
            let fileName = fileNameBasedOnType(of: ToCache.self)
            let toCache = try makeCachable()
            try cacher.save(model: toCache, fileName: fileName)
            return toCache
        }

        // Special case, output was cached => Done!
        if startStep >= .stepC, let cached = loadCached(step: stepC) {
            return cached
        }

        // Bah, lots of logic....
        if startStep == .stepB, let cached = loadCached(step: stepB) {
            return try cache(cached |> stepC)
        }

        if startStep == .stepA, let cached = loadCached(step: stepA) {
            let outputB = try cache(cached |> stepB)
            return try cache(outputB |> stepC)
        }

        let outputA = try cache(input |> stepA)
        let outputB = try cache(outputA |> stepB)
        return try cache(outputB |> stepC)
    }
}

final class VanillaTests: XCTestCase {

    private lazy var a = A(int: 42)
    private lazy var b = B(a: a)
    private lazy var c = C(b: b)
    private lazy var d = D(c: c)

    func testCacher() throws {
        let cacher = Cacher()
        try cacher.save(model: d)
        let loaded: D = try cacher.load()
        XCTAssertEqual(d, loaded)
    }

    func testFlow() throws {
        let discManager = OnDiscDataManager.temporary()
        XCTAssertEqual(discManager.numberOfSavedEntries, 0)
        try doTest(
            expectedOutput: d,
            expectedNumberOfStepsTaken: 3,
            discManager: discManager,
            input: a
        )
        XCTAssertEqual(discManager.numberOfSavedEntries, 3)

    }

    static var allTests = [
        ("testCacher", testCacher),
        ("testFlow", testFlow),
    ]
}

private extension Cacher {

    func save<Model>(
        model: Model,
        functionNameAsFileName fileName: String = #function
    ) throws where Model: Codable {
        try save(model: model, fileName: fileName)
    }

    func load<Model>(
        modelType _: Model.Type,

        functionNameAsFileName fileName: String = #function
    ) throws -> Model where Model: Codable {
        try load(modelType: Model.self, fileName: fileName)
    }

    func load<Model>(
        functionNameAsFileName: String = #function
    ) throws -> Model where Model: Codable {
        try load(modelType: Model.self, functionNameAsFileName: functionNameAsFileName)
    }
}

private extension VanillaTests {

    func doTest(
        expectedOutput: D,
        expectedNumberOfStepsTaken: Int,

        discManager: OnDiscDataManager,

        input: A = .irrelevant,
        startAt startStep: StartStep? = nil,

        nameOfFlow: String = #function,
        line: UInt = #line
    ) throws {
        let cacher = Cacher(onDisc: discManager)

        try doTest(
            expectedOutput: expectedOutput,
            expectedNumberOfStepsTaken: expectedNumberOfStepsTaken,
            cacher: cacher,
            input: input,
            startAt: startStep,

            nameOfFlow: nameOfFlow,
            line: line
        )
    }

    func doTest(
        expectedOutput: D,
        expectedNumberOfStepsTaken: Int,

        cacher: Cacher = .init(),

        input: A = .irrelevant,
        startAt startStep: StartStep? = nil,

        nameOfFlow: String = #function,
        line: UInt = #line
    ) throws {
        let cachedFlow = CachedFlow<A, D>(cacher: cacher)

        let output: D = try cachedFlow.flowOf(
            fileName: nameOfFlow,
            input: input,
            startAt: startStep,

            AtoB(),
            BtoC(),
            CtoD()
        )

        XCTAssertEqual(
            output, expectedOutput,
            "Expected `output` of flow to equal: '\(expectedOutput)', but got: '\(output)'",
            line: line
        )

//        XCTAssertEqual(
//            cachedFlow.stepsTakenInLastFlow,
//            expectedNumberOfStepsTaken,
//            "Expected `cachedFlow.stepsTakenInLastFlow` to equal: '\(expectedNumberOfStepsTaken)', but got: '\(cachedFlow.stepsTakenInLastFlow)'",
//            line: line
//        )
    }
}

extension A {
    static let irrelevant = Self(int: 1337)
}
