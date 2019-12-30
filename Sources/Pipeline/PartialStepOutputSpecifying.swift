//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2019-12-30.
//

import Foundation

// MARK: PartialStepOutputSpecifying

/// A *partially* type-erased `step` specifying expected `Output`, but not `Input` type.
public struct PartialStepOutputSpecifying<Output>: PartialUnsafeStepOutputSpecifying where Output: Codable {


    public let name: String
    private let _perform: (_ anyInput: Any) throws -> Output

    public init(name: String, perform: @escaping (Any) throws -> Output) {
        self.name = name
        self._perform = perform
    }

//    public init(unsafeStep: UnsafeStep) {
//        self.init(
//            name: unsafeStep.name
//        ) {
//            try unsafeStep.unsafePerform(anyInput: $0)
//        }
//    }
}

//// MARK: Init
//public extension PartialStepOutputSpecifying {
//    init<S>(_ step: S)
//        where
//        S: Step,
//        S.Input == Input
//        //        S.Output == Output
//    {
//        self.init(name: step.name) { (input: S.Input) in
//            try step.perform(input: input)
//        }
//    }
//}

// MARK: PartialUnsafeStepInputSpecifying
public extension PartialStepOutputSpecifying {
    func partialUnsafePerform(anyInput: Any) throws -> Output {
        try _perform(anyInput)
    }

    func loadCached(from cacher: Cacher, fileName: String) -> Any? {
        fatalError()
    }

    func cache(_ any: Any, in cacher: Cacher, fileName: String) throws {
        fatalError()
    }
}
