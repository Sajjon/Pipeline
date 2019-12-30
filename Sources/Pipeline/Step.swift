//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2019-12-13.
//

import Foundation

public protocol Named {}

public struct AnyJSONDecoding {
    private let _decode: (Data, JSONDecoder) throws -> Any
    init<Model: Codable>(type _: Model.Type) {
        self._decode = { try $1.decode(Model.self, from: $0) }
    }
    func decode(data: Data, using decoder: JSONDecoder = .init()) throws -> Any {
        try self._decode(data, decoder)
    }
}

public struct AnyJSONEncoding {
    private let _encode: (Any, JSONEncoder) throws -> Data
    init<Model: Codable>(type _: Model.Type) {
        self._encode = {
            let model: Model = castOrKill($0)
            return try $1.encode(model)
        }
    }
    func encode(_ encodable: Any, using encoder: JSONEncoder = .init()) throws -> Data {
        try self._encode(encodable, encoder)
    }
}

func decode<Model: Codable>(data: Data, as _: Model.Type) throws -> Model {
    let decoding = AnyJSONDecoding(type: Model.self)
    let decoded = try decoding.decode(data: data)
    let model: Model = castOrKill(decoded)
    return model
}

func encode<Model: Codable>(model: Model) throws -> Data {
    let encoding = AnyJSONEncoding(type: Model.self)
    return try encoding.encode(model)
}

// MARK: UnsafeStep
public protocol UnsafeStep: Named {
    func unsafePerform(anyInput: Any) throws -> Any



//    func loadCached(from cacher: Cacher, fileName: String) -> Any?
    var encoding: AnyJSONEncoding { get }
    var decoding: AnyJSONDecoding { get }
//    func cache(_ any: Any, in cacher: Cacher, fileName: String) throws
}

public extension UnsafeStep {
    var encoding: AnyJSONEncoding { fatalError() }
    var decoding: AnyJSONDecoding { fatalError() }
}

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



public protocol PartialUnsafeStepOutputSpecifying: UnsafeStep {
    associatedtype Output: Codable
    func partialUnsafePerform(anyInput: Any) throws -> Output
}

public extension PartialUnsafeStepOutputSpecifying {
    func unsafePerform(anyInput: Any) throws -> Any {
        try partialUnsafePerform(anyInput: anyInput)
    }
}


// MARK: Step
//public protocol Step: PartialUnsafeStepInputSpecifying {
public protocol Step: PartialUnsafeStepOutputSpecifying {
    associatedtype Input: Codable
//    associatedtype Output
    func perform(input: Input) throws -> Output
}

public extension Step {
    func partialUnsafePerform(anyInput: Any) throws -> Output {
        guard let input = anyInput as? Input else {
            throw UnsafeStepError.cannotPerform(
                step: self.name,
                withInput: anyInput,
                ofType: typeName(of: anyInput),
                expectedInputType: typeName(of: Input.self)
            )
        }

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

extension Step where Output: Codable {
    func loadCached(from cacher: Cacher, fileName: String) -> Any? {
        loadCachedOutput(from: cacher, fileName: fileName)
    }

    func loadCachedOutput(from cacher: Cacher, fileName: String) -> Output? {
        let maybeCached = try? cacher.load(modelType: Output.self, fileName: fileName)
        if let foundCached = maybeCached {
            print("💾 found cached data: '\(foundCached)' for step: '\(self.name)'")
        } else {
            print("❌ Found no cached data for step: '\(self.name)'")
        }
        return maybeCached
    }

    func cache(_ any: Any, in cacher: Cacher, fileName: String) throws {
        let toCache: Output = castOrKill(any)
        try cacheOutput(toCache, in: cacher, fileName: fileName)
    }

    func cacheOutput(_ output: Output, in cacher: Cacher, fileName: String) throws {
        try cacher.save(model: output, fileName: fileName)
    }
}

public extension Named {
    var name: String { typeName(of: self) }
}

func typeName(of any: Any) -> String {
    .init(describing: Mirror(reflecting: any).subjectType)
}
