//
//  FieldExtension.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/20/16.
//
//

import Foundation
import SwiftPoet

extension Field {
    public var cammelCaseName: String {
        return PoetUtil.cleanCammelCaseString(self.name)
    }

    public func clone(withTypeName typeName: String) -> Field {
        return Field(name: name, type: typeName, description: description, deprecation: deprecation, _default: _default, required: required, minimum: minimum, maximum: maximum, example: example)
    }
}
