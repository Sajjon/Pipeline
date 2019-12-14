//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2019-12-14.
//

import Foundation

func incorrectImplementation(_ reason: String) -> Never {
    fatalError("Incorrect implementation - \(reason)")
}

func incorrectImplementationShouldAlwaysBeAble(to expected: String) -> Never {
    incorrectImplementation("Should always be able to: \(expected)")
}

func unexpectedlyCaughtError(_ error: Swift.Error) -> Never {
    incorrectImplementation("Should never see error: \(error)")
}

func wrongType<Expected>(
    expected _: Expected.Type,
    butGot instanceOfWrongType: Any
) -> Never {

    let nameOfWrongType = typeName(of: instanceOfWrongType)
    let reason = "⚠️ Wrong type, got value: `\(instanceOfWrongType)` of type: '\(nameOfWrongType)', but expected type: '\(Expected.self)'\n\n"
    incorrectImplementation(reason)
}
