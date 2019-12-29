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

extension Int {
    init?<Integer>(_ maybeInteger: Integer?) where Integer: FixedWidthInteger {
        guard let integer = maybeInteger else { return nil }
        self.init(integer)
    }
}


final class CachedFlow<Input, Output> {

    private let cacher: Cacher
    internal private(set) var numberOfStepsHavingPerformedWork = 0

    init(cacher: Cacher) {
        self.cacher = cacher
    }

    func flowOf(
        fileName: String,
        input: Input,
        startAt maybeStartStepIndex: UInt? = nil,
        useMostProgressedCachedValueEvenIfStartingAtEarlierStep: Bool,
        steps: [UnsafeStep]
    ) throws -> Output {

        let stepIndex = Int(maybeStartStepIndex) ?? (steps.endIndex - 1)

        print("🚀 start flow at step with index: `\(stepIndex)`, named: `\(steps[stepIndex].name)`")

        guard
            stepIndex == (steps.endIndex - 1),
            let lastStep = steps.last,
            let cachedAnyFromLast = lastStep.loadCached(from: cacher, fileName: fileName)
        else {
            return try __innerFlowOf(
                fileName: fileName,
                input: input,
                startAt: stepIndex,
                useMostProgressedCachedValueEvenIfStartingAtEarlierStep: useMostProgressedCachedValueEvenIfStartingAtEarlierStep,
                steps: steps
            )
        }

        // MARK: - Lucky corner case, got cached last
        return castOrKill(cachedAnyFromLast, to: Output.self)
    }

    func __innerFlowOf(
        fileName: String,
        input outerInput: Input,
        startAt indexOfStartStep: Int,
        useMostProgressedCachedValueEvenIfStartingAtEarlierStep: Bool,
        steps: [UnsafeStep]
    ) throws -> Output {

        numberOfStepsHavingPerformedWork = 0

        func loadFromCacheElseMakeNewAndCacheAny(
            performingStepNamed: String,
            shouldLoadFromCache: Bool,
            loadFromCache: () throws -> Any?,
            makeOutput: () throws -> Any,
            cacheOutput: (Any) throws -> Void
        ) throws -> Any {

            func makeAndCache() throws -> Any {
                defer { numberOfStepsHavingPerformedWork += 1 }
                print("🏋️‍♀️ performing work of step named: `\(performingStepNamed)`")
                let newOutput = try makeOutput()
                try cacheOutput(newOutput)
                return newOutput
            }

            if shouldLoadFromCache, let cached = try loadFromCache() {
                return cached
            } else {
                return try makeAndCache()
            }
        }

        func load(fromStep unsafeStep: UnsafeStep) -> Any? {
            unsafeStep.loadCached(from: cacher, fileName: fileName)
        }

        func save(any: Any, forStep unsafeStep: UnsafeStep) throws {
            try unsafeStep.cache(any, in: cacher, fileName: fileName)
        }

        func perform(anyInput: Any, step unsafeStep: UnsafeStep) throws -> Any {
            try unsafeStep.unsafePerform(anyInput: anyInput)
        }

        func loadFromCacheElseMakeNewAndCacheFromUnsafeStep(
            anyInput: Any,
            shouldLoadFromCache: Bool,
            unsafeStep: UnsafeStep
        ) throws -> Any {
            try loadFromCacheElseMakeNewAndCacheAny(
                performingStepNamed: unsafeStep.name,
                shouldLoadFromCache: shouldLoadFromCache,
                loadFromCache: { load(fromStep: unsafeStep) },
                makeOutput: { try perform(anyInput: anyInput, step: unsafeStep) },
                cacheOutput: { try save(any: $0, forStep: unsafeStep) }
            )
        }

        func recursivelyPerformStep(
            at stepIndex: Int,
            shouldLoadFromCache: Bool,
            input latestResult: Any
        ) throws -> Any {

            guard stepIndex < steps.endIndex else {
                // Base case of recursion => done
                return latestResult
            }

            // Recursive call

            let cachedResult = try loadFromCacheElseMakeNewAndCacheFromUnsafeStep(
                anyInput: latestResult,
                shouldLoadFromCache: shouldLoadFromCache,
                unsafeStep: steps[stepIndex]
            )

            return try recursivelyPerformStep(
                at: stepIndex + 1,
                shouldLoadFromCache: shouldLoadFromCache,
                input: cachedResult
            )
        }

        /// Finds the most progressed cached result starting at `indexOfStartStep`, and going back to the first step at index 0.
        func findMostProgressedResultFromStep(_ indexOfStartStep: Int) -> (mostProgressResult: Any, startAtIndex: Int)? {
            var indexOfStep = indexOfStartStep
            repeat {
                defer { indexOfStep -= 1}
                print("⭐️accessing step at index: \(indexOfStep)")
                guard let mostProgressedCachedResult = load(fromStep: steps[indexOfStep]) else { continue }
                return (mostProgressedCachedResult, indexOfStep)
            } while indexOfStep > 0
            return nil

        }

        var mostProgressResult: Any = outerInput
        var nextIndex = 0

        if
            indexOfStartStep > 0, // only find most progressed result if start index is greater than 0
            let tuple = findMostProgressedResultFromStep(indexOfStartStep)
        {
            mostProgressResult = tuple.mostProgressResult
            nextIndex = tuple.startAtIndex
        }

        print("🦦 starting pipeline at step: `\(steps[nextIndex].name)` at index: \(nextIndex), with input: <\(mostProgressResult)>")

        let outputOfPipelineAsAny = try recursivelyPerformStep(
            at: nextIndex,
            shouldLoadFromCache: (nextIndex > 0 || useMostProgressedCachedValueEvenIfStartingAtEarlierStep),
            input: mostProgressResult
        )

        guard let output = outputOfPipelineAsAny as? Output else {
            incorrectImplementationShouldAlwaysBeAble(to: "Cast last output to Output")
        }
        return output

    }
}
