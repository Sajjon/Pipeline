//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2019-12-13.
//

import Foundation

public protocol Named {}

public protocol UnsafeStep: Named {
    func unsafePerform(anyInput: Any) throws -> Any
    func loadCached(from cacher: Cacher, fileName: String) -> Any?
    func cache(_ any: Any, in cacher: Cacher, fileName: String) throws
}

// MARK: Step
public protocol Step: UnsafeStep {
    associatedtype Input
    associatedtype Output
    func perform(input: Input) throws -> Output
}


extension Step {
    func unsafePerform(anyInput: Any) throws -> Any {
        let input: Input = castOrKill(anyInput)
        return try perform(input: input)
    }
}

extension Step where Output: Codable {
    func loadCached(from cacher: Cacher, fileName: String) -> Any? {
        loadCachedOutput(from: cacher, fileName: fileName)
    }

    func loadCachedOutput(from cacher: Cacher, fileName: String) -> Output? {


        //        func loadCached<S>(step: S) -> S.Output? where S: Step, S.Output: Codable {
        let maybeCached = try? cacher.load(modelType: Output.self, fileName: fileName)
        if let foundCached = maybeCached {
            print("💾 found cached data: '\(foundCached)' for step: '\(self.name)'")
        } else {
            print("🙅‍♀️ Found no cached data for step: '\(self.name)'")
        }
        return maybeCached
        //        }

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
