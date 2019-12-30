//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2019-12-14.
//

import Foundation

public final class CacheableWorkFlow<Input, Output> {

    private let cacher: Cacher
    internal private(set) var numberOfStepsHavingPerformedWork = 0

    public init(cacher: Cacher) {
        self.cacher = cacher
    }
}

// MARK: Public
public extension CacheableWorkFlow {

    func startWorkFlow(
        named nameOfWorkFlow: String,
        startAtStep maybeStartStepIndex: UInt? = nil,
        useMostProgressedCachedValueEvenIfStartingAtEarlierStep: Bool = false,
        input: Input,
        steps: [UnsafeStep]
    ) throws -> Output {

        let stepIndex = Int(maybeStartStepIndex) ?? (steps.endIndex - 1)

        print("🚀 start flow at step with index: `\(stepIndex)`, named: `\(steps[stepIndex].name)`")

        guard
            stepIndex == (steps.endIndex - 1),
            let lastStep = steps.last
//            , let cachedAnyFromLast = lastStep.loadCached(from: cacher, fileName: nameOfWorkFlow)
        else {
            return try doPerform(
                steps: steps,
                startAt: stepIndex,
                useMostProgressedCachedValueEvenIfStartingAtEarlierStep: useMostProgressedCachedValueEvenIfStartingAtEarlierStep,
                inputForFirstStep: input,
                nameOfWorkFlow: nameOfWorkFlow
            )
        }
        let cachedAnyFromLast = "APA"
        fatalError()

        // MARK: - Lucky corner case, got cached last
        guard let output = cachedAnyFromLast as? Output else {
            throw UnsafeStepError.cannotPerform(
                step: lastStep.name,
                withInput: cachedAnyFromLast,
                ofType: typeName(of: cachedAnyFromLast),
                expectedInputType: typeName(of: Output.self)
            )
        }
        return output
    }
}

// MARK: Private
private extension CacheableWorkFlow {

    func doPerform(
        steps: [UnsafeStep],
        startAt indexOfStartStep: Int,
        useMostProgressedCachedValueEvenIfStartingAtEarlierStep: Bool,
        inputForFirstStep outerInput: Input,
        nameOfWorkFlow: String
    ) throws -> Output {

        numberOfStepsHavingPerformedWork = 0

        // MARK: Helper methods
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
//            unsafeStep.loadCached(from: cacher, fileName: nameOfWorkFlow)
            fatalError()
        }

        func save(any: Any, forStep unsafeStep: UnsafeStep) throws {
//            try unsafeStep.cache(any, in: cacher, fileName: nameOfWorkFlow)
            fatalError()
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

        // MARK: Recursion
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


        // MARK: Start arguments

        /// Finds the most progressed cached result starting at `indexOfStartStep`, and going back to the first step at index 0.
        func findMostProgressedResultFromStep(_ indexOfStartStep: Int) -> (mostProgressResult: Any, startAtIndex: Int)? {
            var indexOfStep = indexOfStartStep
            repeat {
                defer { indexOfStep -= 1}
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

        // MARK: Start recursion
        let outputOfPipelineAsAny = try recursivelyPerformStep(
            at: nextIndex,
            shouldLoadFromCache: (nextIndex > 0 || useMostProgressedCachedValueEvenIfStartingAtEarlierStep),
            input: mostProgressResult
        )


        guard let output = outputOfPipelineAsAny as? Output else {
            throw UnsafeStepError.cannotPerform(
                step: steps.last!.name,
                withInput: outputOfPipelineAsAny,
                ofType: typeName(of: outputOfPipelineAsAny),
                expectedInputType: typeName(of: Output.self)
            )
        }

        return output

    }
}
