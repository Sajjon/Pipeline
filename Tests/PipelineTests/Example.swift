//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2019-12-31.
//

import Foundation
import Pipeline
import Core

func typeName(of any: Any) -> String {
    .init(describing: Mirror(reflecting: any).subjectType)
}

protocol IntHolder: CacheableResult, Equatable, Codable, CustomStringConvertible {
    var int: Int { get }
}

extension IntHolder {
    var description: String { "\(typeName(of: self))(\(int))" }
}

struct A: IntHolder, ExpressibleByIntegerLiteral {
    let int: Int
    init(int: Int) {
        self.int = int
    }
    init(integerLiteral value: Int) {
        self.init(int: value)
    }
}


protocol IntHolderByProxy: IntHolder {
    associatedtype Proxy: IntHolder
    var proxy: Proxy { get }
    init(proxy: Proxy)
}

extension IntHolderByProxy {
    var int: Int { proxy.int }
    init(_ proxy: Proxy) {
        self.init(proxy: proxy)
    }
}

struct B: IntHolderByProxy {
    typealias Proxy = A
    let proxy: Proxy
}

struct C: IntHolderByProxy {
    typealias Proxy = B
    let proxy: Proxy
}

struct D: IntHolderByProxy {
    typealias Proxy = C
    let proxy: Proxy
}

protocol ChainedIntStep: Step where Output: IntHolderByProxy, Output.Proxy == Input {}

extension ChainedIntStep {
    func perform(input: Input) throws -> Output {
        Output.init(input)
    }
}

struct AtoB: ChainedIntStep {
    typealias Input = A
    typealias Output = B
}

struct BtoC: ChainedIntStep {
    typealias Input = B
    typealias Output = C
}

struct CtoD: ChainedIntStep {
    typealias Input = C
    typealias Output = D
}

struct DtoE: ChainedIntStep {
    typealias Input = C
    typealias Output = D
}
