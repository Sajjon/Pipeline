//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2019-12-31.
//

import Foundation
import Core

final class StepLinker {
    var steps = [AnyStep]()
    private var _link: (AnyStep) -> AnyStep
    
    init<S>(_ step: S) where S: Step {
        let anyStep = AnyStep(step)
        defer { steps.append(anyStep) }
        _link = { anyStep.bind(to: $0) }
    }
}

extension AnyStep {
    init<S>(_ step: S) where S: Step {
        self.init(
            name: step.name,
            cacheableResultType: step.cacheableResultTypeIfAny
        ) { (input: S.Input) in
            try step.perform(input: input)
        }
    }
}

// MARK: Internal
extension StepLinker {
    func link<S>(_ step: S) where S: Step {
        let anyStep = AnyStep(step)
        defer {
            _link = { anyStep.bind(to: $0) }
        }
        let linked = _link(anyStep)
        steps.append(linked)
    }
}
