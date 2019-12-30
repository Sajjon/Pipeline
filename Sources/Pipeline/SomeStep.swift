//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2019-12-29.
//

import Foundation

// MARK: SomeStep
public struct SomeStep<Input, Output>: Step where Output: Codable, Input: Codable {


    public let name: String
    private let _perform: (_ input: Input) throws -> Output

    public init(name: String, perform: @escaping (Input) throws -> Output) {
        self.name = name
        self._perform = perform
    }

    //    public init(unsafeStep: UnsafeStep) {
    //        self.name = unsafeStep.name
    //        self.
    //    }
}

// MARK: Init
public extension SomeStep {
    init<S>(_ step: S)
        where
        S: Step,
        S.Input == Input,
        S.Output == Output
    {
        self.init(name: step.name) { (input: S.Input) in
            try step.perform(input: input)
        }
    }
}

// MARK: Step
public extension SomeStep {
    func perform(input: Input) throws -> Output {
        try _perform(input)
    }

    func loadCached(from cacher: Cacher, fileName: String) -> Any? {
        fatalError()
    }

    func cache(_ any: Any, in cacher: Cacher, fileName: String) throws {
        fatalError()
    }
}
