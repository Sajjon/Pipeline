//
//  File.swift
//  
//
//  Created by Alexander Cyon on 2019-12-30.
//

import Foundation

extension Int {
    init?<Integer>(_ maybeInteger: Integer?) where Integer: FixedWidthInteger {
        guard let integer = maybeInteger else { return nil }
        self.init(integer)
    }
}
