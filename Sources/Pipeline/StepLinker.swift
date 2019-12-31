//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2019-12-31.
//

import Foundation
import Core

struct StepLinker {
    var steps = [AnyStep]()
    private var _link: (AnyStep) -> AnyStep
    
    init<S>(_ step: S) where S: Step {
        let anyStep = AnyStep(step)
        defer { steps.append(anyStep) }
        _link = { anyStep.bind(to: $0) }
    }
}

extension AnyStep {
    init<S>(_ step: S) where S: Step {
        self.init(
            name: step.name,
            cacheableResultType: step.cacheableResultTypeIfAny
        ) { (input: S.Input) in
            try step.perform(input: input)
        }
    }
}

// MARK: Private
private extension StepLinker {
    mutating func link<S>(_ step: S) where S: Step {
        let anyStep = AnyStep(step)
        defer {
            _link = { anyStep.bind(to: $0) }
        }
        let linked = _link(anyStep)
        steps.append(linked)
    }
}

// MARK: FunctionBuilder
extension StepLinker {
    @_functionBuilder
    struct LinkerBuilder {
        
        // MARK: 2 Steps
        static func buildBlock<A, B>(
            _ a: A,
            _ b: B
        ) -> StepLinker
            where
            A: Step,
            B: Step
        {
            var linker = StepLinker(a)
            linker.link(b)
            return linker
        }
        
        // MARK: 3 Steps
        static func buildBlock<A, B, C>(
            _ a: A,
            _ b: B,
            _ c: C
        ) -> StepLinker
            where
            A: Step,
            B: Step,
            C: Step
        {
            var linker = StepLinker(a)
            linker.link(b)
            linker.link(c)
            return linker
        }
        
        // MARK: 4 Steps
        static func buildBlock<A, B, C, D>(
            _ a: A,
            _ b: B,
            _ c: C,
            _ d: D
        ) -> StepLinker
            where
            A: Step,
            B: Step,
            C: Step,
            D: Step
        {
            var linker = StepLinker(a)
            linker.link(b)
            linker.link(c)
            linker.link(d)
            return linker
        }
        
        // MARK: 5 Steps
        static func buildBlock<A, B, C, D, E>(
            _ a: A,
            _ b: B,
            _ c: C,
            _ d: D,
            _ e: E
        ) -> StepLinker
            where
            A: Step,
            B: Step,
            C: Step,
            D: Step,
            E: Step
        {
            var linker = StepLinker(a)
            linker.link(b)
            linker.link(c)
            linker.link(d)
            linker.link(e)
            return linker
        }
        
        // MARK: 6 Steps
        static func buildBlock<A, B, C, D, E, F>(
            _ a: A,
            _ b: B,
            _ c: C,
            _ d: D,
            _ e: E,
            _ f: F
        ) -> StepLinker
            where
            A: Step,
            B: Step,
            C: Step,
            D: Step,
            E: Step,
            F: Step
        {
            var linker = StepLinker(a)
            linker.link(b)
            linker.link(c)
            linker.link(d)
            linker.link(e)
            linker.link(f)
            return linker
        }
        
        // MARK: 7 Steps
        static func buildBlock<A, B, C, D, E, F, G>(
            _ a: A,
            _ b: B,
            _ c: C,
            _ d: D,
            _ e: E,
            _ f: F,
            _ g: G
        ) -> StepLinker
            where
            A: Step,
            B: Step,
            C: Step,
            D: Step,
            E: Step,
            F: Step,
            G: Step
        {
            var linker = StepLinker(a)
            linker.link(b)
            linker.link(c)
            linker.link(d)
            linker.link(e)
            linker.link(f)
            linker.link(g)
            return linker
        }
    }
}

// MARK: StepLinker from FunctionBuilder
extension StepLinker {
    init(@LinkerBuilder makeLinker: () -> StepLinker) {
        self = makeLinker()
    }
    
}
