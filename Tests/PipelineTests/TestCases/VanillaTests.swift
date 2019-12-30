//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2019-12-14.
//

import XCTest
@testable import Pipeline

final class VanillaTests: XCTestCase {

    private lazy var a = A(int: 42)
    private lazy var b = B(a)
    private lazy var c = C(b)
    private lazy var d = D(c)

    private let discManager = OnDiscDataManager.temporary()

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        discManager.recreateTemporaryDirectoryIfNeeded()
    }

    override func tearDown() {
        super.tearDown()
        discManager.removeTemporaryDirectory()
    }

    override class func tearDown() {
        super.tearDown()
        OnDiscDataManager.removeTemporaryRootDirectoryIfNeeded()
    }

    private func makeCacher() -> Cacher {
        Cacher(onDisc: discManager)
    }

    func testCacher() throws {
        let cacher = makeCacher()
        try cacher.save(model: d)
        let loaded: D = try cacher.load()
        XCTAssertEqual(d, loaded)
    }

    func testFlowNothingCached() throws {

        let cacher = makeCacher()
        XCTAssertEqual(cacher.numberOfSavedEntries, 0)
        try doTest(
            expectedOutput: d,
            expectedNumberOfStepsTaken: 3,
            cacher: cacher,
            input: a
        )
        XCTAssertEqual(cacher.numberOfSavedEntries, 3)
    }


    func testFlowStepACachedStartAtA() {
        do {
            let cacher = makeCacher()
            XCTAssertEqual(cacher.numberOfSavedEntries, 0)
            try cacher.save(model: b)
            XCTAssertEqual(cacher.numberOfSavedEntries, 1)
            let input: A = .init(int: 5)
            try doTest(
                expectedOutput: D(C(B(input))),
                expectedNumberOfStepsTaken: 3,
                cacher: cacher,
                useMostProgressedCachedValueEvenIfStartingAtEarlierStep: false,
                input: input,
                startAt: 0
            )
            XCTAssertEqual(cacher.numberOfSavedEntries, 3)
        } catch {
            XCTFail("error: \(error)")
        }
    }

    func testFlowStepACachedStartAtAForceUseCaced() {
        do {
            let cacher = makeCacher()
            XCTAssertEqual(cacher.numberOfSavedEntries, 0)
            try cacher.save(model: b)
            XCTAssertEqual(cacher.numberOfSavedEntries, 1)
            try doTest(
                expectedOutput: d,
                expectedNumberOfStepsTaken: 2,
                cacher: cacher,
                useMostProgressedCachedValueEvenIfStartingAtEarlierStep: true,
                input: A(int: 1337),
                startAt: 0
            )
            XCTAssertEqual(cacher.numberOfSavedEntries, 3)
        } catch {
            XCTFail("error: \(error)")
        }
    }

    func testFlowStepBCachedStartAtB() throws {
        let cacher = makeCacher()
        XCTAssertEqual(cacher.numberOfSavedEntries, 0)
        try cacher.save(model: c)
        XCTAssertEqual(cacher.numberOfSavedEntries, 1)
        try doTest(
            expectedOutput: d,
            expectedNumberOfStepsTaken: 1,
            cacher: cacher,
            input: A(int: 1337),
            startAt: 1
        )
        XCTAssertEqual(cacher.numberOfSavedEntries, 2)
    }

    func testFlowStepBCachedStartAtA() throws {
        let cacher = makeCacher()
        XCTAssertEqual(cacher.numberOfSavedEntries, 0)
        try cacher.save(model: c)
        XCTAssertEqual(cacher.numberOfSavedEntries, 1)
        try doTest(
            expectedOutput: d,
            expectedNumberOfStepsTaken: 3,
            cacher: cacher,
            input: a,
            startAt: 0
        )
        XCTAssertEqual(cacher.numberOfSavedEntries, 3)
    }

    static var allTests = [
        ("testCacher", testCacher),
//        ("testFlowNothingCached", testFlowNothingCached),
//        ("testFlowStepACachedStartAtA", testFlowStepACachedStartAtA),
//        ("testFlowStepBCachedStartAtB", testFlowStepBCachedStartAtB),
//        ("testFlowStepBCachedStartAtA", testFlowStepBCachedStartAtA),
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

        cacher: Cacher,
        useMostProgressedCachedValueEvenIfStartingAtEarlierStep: Bool = false,
        input: A,
        startAt maybeStartStepIndex: UInt? = nil,

        nameOfFlow: String = #function,
        line: UInt = #line
    ) throws {
        let cachedFlow = CacheableWorkFlow<A, D>(cacher: cacher)


        let output: D = try cachedFlow.startWorkFlow(
            named: nameOfFlow,
            startAtStep: maybeStartStepIndex,
            useMostProgressedCachedValueEvenIfStartingAtEarlierStep: useMostProgressedCachedValueEvenIfStartingAtEarlierStep,
            input: input,

            steps: [
                AtoB(),
                BtoC(),
                CtoD()
            ]
        )

        XCTAssertEqual(
            output, expectedOutput,
            "Expected `output` of flow to equal: '\(expectedOutput)', but got: '\(output)'",
            line: line
        )

        XCTAssertEqual(
            cachedFlow.numberOfStepsHavingPerformedWork,
            expectedNumberOfStepsTaken,
            "Expected `cachedFlow.numberOfStepsHavingPerformedWork` to equal: '\(expectedNumberOfStepsTaken)', but got: '\(cachedFlow.numberOfStepsHavingPerformedWork)'",
            line: line
        )
    }
}
