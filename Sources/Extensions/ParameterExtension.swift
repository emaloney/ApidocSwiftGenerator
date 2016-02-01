//
//  ParameterExtension.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/29/16.
//
//

import Foundation
import SwiftPoet

extension Parameter {
    public var cammelCaseName: String {
        return PoetUtil.cleanCammelCaseString(self.name)
    }

    internal var typeName: String {
        return TypeName(keyword: type, optional: !required, imports: nil).literalValue()
    }
}
