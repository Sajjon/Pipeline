//
//  File.swift
//
//
//  Created by Alexander Cyon on 2019-12-13.
//

import Foundation
import Core

// MARK: Pipeline
public struct Pipeline<Input, Output>: CustomStringConvertible {
    
    public let description: String
    private let _perform: (Input) throws -> Output
    
    fileprivate init(description: String, perform: @escaping (Input) throws -> Output) {
        self.description = description
        self._perform = perform
    }
}

// MARK: Init
private extension Pipeline {
    /// Assumes that the steps are indeed pipeable, that is, that the input of step
    /// `s_0` is of type `Self.Input`, and its output equals `Input` of `s_1`... and that the
    /// `Output` type of `s_n` equals `Self.Output`
    init(
        cacher: Cacher = Cacher(onDisc: .temporary()),
        description: String,
        steps: [AnyStep]
    ) {
        
        let workFlow = CacheableWorkFlow<Input, Output>(cacher: cacher)
        
        self.init(description: description) {
            return try workFlow.startWorkFlow(
                named: description,
                input: $0,
                steps: steps
            )
        }
    }
    
    init(
        cacher: Cacher = Cacher(onDisc: .temporary()),
        stepLinker: StepLinker
    ) {
        
        let anySteps = stepLinker.steps
        
        self.init(
            cacher: cacher,
            description: names(of: anySteps),
            steps: anySteps
        )
    }
}

public extension Pipeline {
    func perform(input: Input) throws -> Output {
        try _perform(input)
    }
}

public extension Pipeline {
    init(@Builder makePipeline: () -> Self) {
        self = makePipeline()
    }
}

// MARK: Builder
public extension Pipeline {
    @_functionBuilder
    struct Builder {}
}

public extension Pipeline.Builder {
    
    // MARK: 2 Steps
    static func buildBlock<Input, Output, A, B>(
        _ a: A,
        _ b: B
    ) -> Pipeline<Input, Output>
        
        where
        
        A: Step,
        B: Step,
        
        A.Output == B.Input,
        
        Input == A.Input,
        Output == B.Output
    {
        let linker = StepLinker(a)
        linker.link(b)
        
        return Pipeline<A.Input, B.Output>(
            stepLinker: linker
        )
    }
    
    // MARK: 3 Steps
    static func buildBlock<Input, Output, A, B, C>(
        _ a: A,
        _ b: B,
        _ c: C
    ) -> Pipeline<Input, Output>
        
        where
        
        A: Step,
        B: Step,
        C: Step,
        
        A.Output == B.Input,
        B.Output == C.Input,
        
        Input == A.Input,
        Output == C.Output
    {
        let linker = StepLinker(a)
        linker.link(b)
        linker.link(c)
        
        return Pipeline<A.Input, C.Output>(
            stepLinker: linker
        )
    }
    
    // MARK: 4 Steps
    static func buildBlock<Input, Output, A, B, C, D>(
        _ a: A,
        _ b: B,
        _ c: C,
        _ d: D
    ) -> Pipeline<Input, Output>

        where
        
        A: Step,
        B: Step,
        C: Step,
        D: Step,
        
        A.Output == B.Input,
        B.Output == C.Input,
        C.Output == D.Input,
        
        Input == A.Input,
        Output == D.Output
    {
        
        let linker = StepLinker(a)
        linker.link(b)
        linker.link(c)
        linker.link(d)
        
        return Pipeline<Input, Output>(
            stepLinker: linker
        )
    }
    
    // MARK: 5 Steps
    static func buildBlock<Input, Output, A, B, C, D, E>(
        _ a: A,
        _ b: B,
        _ c: C,
        _ d: D,
        _ e: E
    ) -> Pipeline<Input, Output>
        
        where
        
        A: Step,
        B: Step,
        C: Step,
        D: Step,
        E: Step,
        
        A.Output == B.Input,
        B.Output == C.Input,
        C.Output == D.Input,
        D.Output == E.Input,
        
        Input == A.Input,
        Output == E.Output
    {
        let linker = StepLinker(a)
        linker.link(b)
        linker.link(c)
        linker.link(d)
        linker.link(e)
       
        return Pipeline<Input, Output>(
            stepLinker: linker
        )
    }
}

func names(of steps: [__built_in_UnsafeStep], separator: String = " -> ") -> String {
    steps.map { $0.name }.joined(separator: separator)
}
