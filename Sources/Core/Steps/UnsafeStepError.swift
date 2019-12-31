//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2019-12-31.
//

import Foundation

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
