//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2019-12-13.
//

import Foundation

public protocol Named {}

// MARK: Step
public protocol Step: Named {
    associatedtype Input
    associatedtype Output
    func perform(input: Input) throws -> Output
}

public extension Named {
    var name: String {
        .init(describing: Mirror(reflecting: self).subjectType)
    }
}

