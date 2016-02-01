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
    internal var cammelCaseName: String {
        return PoetUtil.cleanCammelCaseString(self.name)
    }

    internal var typeName: String {
        return TypeName(keyword: type, optional: !required, imports: nil).literalValue()
    }

    internal var requiredTypeName: String {
        return TypeName(keyword: type, optional: false, imports: nil).literalValue()
    }

    internal func clone(withTypeName typeName: String) -> Field {
        return Field(name: name, type: typeName, description: description, deprecation: deprecation, _default: _default, required: required, minimum: minimum, maximum: maximum, example: example)
    }
}
