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
    internal private(set) var stepsTakenInLastFlow = 0

    init(cacher: Cacher) {
        self.cacher = cacher
    }

    func flowOf(
        fileName: String,
        input outerInput: Input,
        startAt maybeStartStepIndex: UInt? = nil,
        steps: [UnsafeStep]
    ) throws -> Output {

        stepsTakenInLastFlow = 0

        func workAndCache(
            makeOutput: () throws -> Any,
            cacheOutput: (Any) throws -> Void
        ) throws -> Any {
            let newOutput = try makeOutput()
            stepsTakenInLastFlow += 1
            try cacheOutput(newOutput)
            return newOutput
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

        func workAndCacheWithStep(
            anyInput: Any,
            unsafeStep: UnsafeStep
        ) throws -> Any {
            try workAndCache(
                makeOutput: { try perform(anyInput: anyInput, step: unsafeStep) },
                cacheOutput: { try save(any: $0, forStep: unsafeStep) }
            )
        }

        let indexOfStartStep = min(Int(maybeStartStepIndex) ?? steps.endIndex, steps.endIndex)

        if indexOfStartStep == steps.endIndex, let lastStep = steps.last, let cachedAnyFromLast = load(fromStep: lastStep) {
            // MARK: - Lucky corner case, got cached last
            return castOrKill(cachedAnyFromLast, to: Output.self)
        }

        // MARK: - Last not cached => some work needed
        print("🤷‍♀️ Output of last step no cached, we gotta do some work")

        func findMostProgressedCachedResultIfAny(s0meStartInd3x: Int) -> (outputOfLastStep: Any, fromStepAtIndex: Int) {
            for indexOfStepOffset in 0..<s0meStartInd3x { // reversed order
                let indexOfStep = s0meStartInd3x - indexOfStepOffset - 1
                let step = steps[indexOfStep]
                guard let mostProgressedCachedResult = load(fromStep: step) else {
                    continue
                }
                print("💡 output of step: `\(step.name)` at index: `\(indexOfStep)`, had cached result: <\(mostProgressedCachedResult)>")
                return (outputOfLastStep: mostProgressedCachedResult, fromStepAtIndex: indexOfStep)
            }
            return (outputOfLastStep: outerInput, fromStepAtIndex: -1)
        }

        func _flowOf(
            input inputOfFunctionAny: Any,
            stepStartIndexFuction: Int
        ) throws -> Any {


            if stepStartIndexFuction >= steps.endIndex {
                let outputOfPipeLineAsAny = inputOfFunctionAny
                print("🌈 stepStartIndexFuction >= steps.endIndex: \(stepStartIndexFuction) >= \(steps.endIndex) => outputting value: <\(outputOfPipeLineAsAny)>")
                return outputOfPipeLineAsAny
            }
            let step = steps[stepStartIndexFuction]
            let newOutput = try workAndCacheWithStep(anyInput: inputOfFunctionAny, unsafeStep: step)
            print("🦶 step: `\(step.name)` at index: `\(stepStartIndexFuction)`, with input: <\(inputOfFunctionAny)> resulted in output: <\(newOutput)>")

            return try _flowOf(input: newOutput, stepStartIndexFuction: stepStartIndexFuction + 1)
        }


        let mostProgressedCachedResult = findMostProgressedCachedResultIfAny(s0meStartInd3x: indexOfStartStep)

        let outputOfPipelineAsAny = try _flowOf(
            input: mostProgressedCachedResult.outputOfLastStep,
            stepStartIndexFuction: mostProgressedCachedResult.fromStepAtIndex + 1
        )

        guard let output = outputOfPipelineAsAny as? Output else {
            incorrectImplementationShouldAlwaysBeAble(to: "Cast last output to Output")
        }
        return output

    }
}
