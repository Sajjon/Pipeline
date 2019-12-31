//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2019-12-31.
//

import Foundation

// MARK: UnsafeStep
public protocol UnsafeStep {
    var name: String { get }
    func unsafePerform(anyInput: Any) throws -> Any
    var cacheableResultTypeIfAny: CacheableResult.Type { get }
}

public extension UnsafeStep {
    var name: String { typeName(of: self) }
}

func typeName(of any: Any) -> String {
    .init(describing: Mirror(reflecting: any).subjectType)
}
