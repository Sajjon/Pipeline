//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2019-12-13.
//

import Foundation

// MARK: UnsafeStep
public protocol UnsafeStep {
    var name: String { get }
    func unsafePerform(anyInput: Any) throws -> Any
    var cacheableResultTypeIfAny: CacheableResult.Type { get }
}

//public struct NoCacheableResult: CacheableResult {}
//public extension NoCacheableResult {
//    static func loadCached(from cacher: Cacher, fileName: String) -> Any? {
//        fatalError()
//    }
//
//    func cache(in cacher: Cacher, fileName: String) throws {
//        fatalError()
//    }
//}
//
//public extension UnsafeStep {
//    var cacheableResultTypeIfAny: CacheableResult.Type { NoCacheableResult.self }
//}

public protocol PartialUnsafeStepInputSpecifying: UnsafeStep {
    associatedtype Input
    func partialUnsafePerform(input: Input) throws -> Any
}

public extension PartialUnsafeStepInputSpecifying {
    func unsafePerform(anyInput: Any) throws -> Any {
        guard let input = anyInput as? Input else {
            throw UnsafeStepError.cannotPerform(
                step: self.name,
                withInput: anyInput,
                ofType: typeName(of: anyInput),
                expectedInputType: typeName(of: Input.self)
            )
        }
        return try partialUnsafePerform(input: input)
    }
}


// MARK: Step
public protocol Step: PartialUnsafeStepInputSpecifying {
    associatedtype Output
    func perform(input: Input) throws -> Output
}

public extension Step where Output: CacheableResult {
    var cacheableResultTypeIfAny: CacheableResult.Type {
        return Output.self
    }
}

public extension Step {
    
    
    func partialUnsafePerform(input: Input) throws -> Any {
        return try perform(input: input)
    }
}


public enum UnsafeStepError: Swift.Error, CustomStringConvertible {
    case cannotPerform(
        step: String,
        withInput: Any,
        ofType: String,
        expectedInputType: String
    )
}

public extension UnsafeStepError {
    var description: String {
        switch self {
            case .cannotPerform(let nameOfStep, let wrongInput, let typeOfWrongInput, let expectedInputType):
            return "cannotPerform step: \(nameOfStep), expected type: \(expectedInputType), but got value: \(wrongInput), of incorrect type: \(typeOfWrongInput)"
        }
    }
}

public extension UnsafeStep {
    var name: String { typeName(of: self) }
}

func typeName(of any: Any) -> String {
    .init(describing: Mirror(reflecting: any).subjectType)
}
