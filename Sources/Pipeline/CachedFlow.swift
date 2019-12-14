//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2019-12-14.
//

import Foundation

enum StartStep: Int, Equatable, Comparable {
    case stepA = 0, stepB, stepC, stepD, stepE, stepF, stepG, stepH, stepI, stepJ
}

extension StartStep {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}


final class CachedFlow<Input, Output> {

    private let cacher: Cacher
    internal private(set) var stepsTakenInLastFlow = 0

    init(cacher: Cacher) {
        self.cacher = cacher
    }

    func flowOf<StepA, StepB, StepC>(
        fileName: String,
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
        stepsTakenInLastFlow = 0

        let startStep: StartStep = maybeStartStep ?? .stepC

        func loadCached<S>(step: S) -> S.Output? where S: Step, S.Output: Codable {
            let maybeCached = try? cacher.load(modelType: S.Output.self, fileName: fileName)
            if let foundCached = maybeCached {
                print("💾 found cached data: '\(foundCached)' for step: '\(step.name)'")
            } else {
                print("🙅‍♀️ Found no cached data for step: '\(step.name)'")
            }
            return maybeCached
        }

        func cache<ToCache>(_ makeCachable: @autoclosure () throws -> ToCache) throws -> ToCache where ToCache: Codable {
            defer { stepsTakenInLastFlow += 1 }
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
