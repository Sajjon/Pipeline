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

enum IfCachedResultOfStepAfterStartIsFound {
    case useCached(overwriteCachedWithNew: Bool)
    case ignoreCachedAndOverwriteItWithNew
}

//extension IfCachedResultOfStepAfterStartIsFound {
//    var shouldUseCached: Bool {
//        switch self {
//            case .useCached: return true
//            case .ignoreCachedAndOverwriteItWithNew: return false
//        }
//    }
//
//    var shouldOverwriteCachedWithNew: Bool {
//        switch self {
//            case .useCached(let shouldOverwrite): return shouldOverwrite
//            case .ignoreCachedAndOverwriteItWithNew: return true
//        }
//    }
//}


final class CachedFlow<Input, Output> {

    private let cacher: Cacher
    internal private(set) var numberOfStepsHavingPerformedWork = 0

    init(cacher: Cacher) {
        self.cacher = cacher
    }

    func flowOf(
        fileName: String,
        input outerInput: Input,
        ifCachedResultOfStepAfterStartIsFound: IfCachedResultOfStepAfterStartIsFound = .ignoreCachedAndOverwriteItWithNew,
        startAt maybeStartStepIndex: UInt? = nil,
        steps: [UnsafeStep]
    ) throws -> Output {

        numberOfStepsHavingPerformedWork = 0

        func loadFromCacheElseMakeNewAndCacheAny(
            performingStepNamed: String,
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

            if let cached = try loadFromCache() {
                switch ifCachedResultOfStepAfterStartIsFound {
                    case .ignoreCachedAndOverwriteItWithNew:
                        return try makeAndCache()
                    case .useCached(let overwriteCachedWithNew):
                        if overwriteCachedWithNew {
                            _ = try makeAndCache()
                        }
                        return cached

                }
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
            unsafeStep: UnsafeStep
        ) throws -> Any {
            try loadFromCacheElseMakeNewAndCacheAny(
                performingStepNamed: unsafeStep.name,
                loadFromCache: { load(fromStep: unsafeStep) },
                makeOutput: { try perform(anyInput: anyInput, step: unsafeStep) },
                cacheOutput: { try save(any: $0, forStep: unsafeStep) }
            )
        }

        let indexOfLastStep = steps.endIndex - 1
        let indexOfStartStep = min(Int(maybeStartStepIndex) ?? indexOfLastStep, indexOfLastStep)

        if indexOfStartStep == indexOfLastStep, let lastStep = steps.last, let cachedAnyFromLast = load(fromStep: lastStep) {
            // MARK: - Lucky corner case, got cached last
            return castOrKill(cachedAnyFromLast, to: Output.self)
        }

        // MARK: - Last not cached => some work needed
        print("🤷‍♀️ Output of last step no cached, we gotta do some work")

        func findMostProgressedCachedResultIfAny(s0meStartInd3x: Int) -> (outputOfLastStep: Any, fromStepAtIndex: Int) {
            print("🔮 findMostProgressedCachedResultIfAny - s0meStartInd3x: `\(s0meStartInd3x)`")
            var indexOfStep = s0meStartInd3x
            while indexOfStep > -1 {
//                let indexOfStep = s0meStartInd3x - indexOfStepOffset - 1
                print("🇸🇪 indexOfStep: \(indexOfStep)")
                let step = steps[indexOfStep]
                defer { indexOfStep -= 1}
                guard let mostProgressedCachedResult = load(fromStep: step) else {
                    print("👻 found no cached result for step named `\(step.name)` at index: `\(indexOfStep)`")
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
            print("🦶 step: `\(step.name)` at index: `\(stepStartIndexFuction)`, with input: <\(inputOfFunctionAny)>")
            let newOutput = try loadFromCacheElseMakeNewAndCacheFromUnsafeStep(anyInput: inputOfFunctionAny, unsafeStep: step)
            print("🦶✅ resulted in output: <\(newOutput)>")
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
