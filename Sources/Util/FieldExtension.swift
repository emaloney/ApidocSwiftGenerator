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

    public var cleanTypeName: String {
        return PoetUtil.cleanTypeName(self.type)
    }

    public func clone(withTypeName typeName: String) -> Field {
        return Field(name: name, type: typeName, description: description, deprecation: deprecation, _default: _default, required: required, minimum: minimum, maximum: maximum, example: example)
    }
}

extension Parameter {
    public var cammelCaseName: String {
        return PoetUtil.cleanCammelCaseString(self.name)
    }

    internal var cleanTypeName: String {
        return TypeName(keyword: type, optional: !required).toString()
    }
}

extension Resource {
    internal func cleanTypeName(operation: Operation) -> String {
        return PoetUtil.cleanTypeName(self.type) + operation.cleanTypeName
    }
}

extension Operation {
    internal var queryParams: [Parameter] {
        return self.params(.Query)
    }

    internal var formParams: [Parameter] {
        return self.params(.Form)
    }

    internal var pathParams: [Parameter] {
        return self.params(.Path)
    }

    private func params(location: ParameterLocation) -> [Parameter] {
        return self.parameters.filter {
            $0.location == location
        }
    }

    internal var cleanTypeName: String {
        let method = PoetUtil.cleanTypeName(self.method.rawValue.lowercaseString)

        let urlPathParts: String = splitPath.filter {
            return $0.characters.first != ":"
        }.map {
            return PoetUtil.cleanTypeName($0)
        }.joinWithSeparator("")

        if pathParams.count > 0 {
            let pathStr = (pathParams.map { PoetUtil.cleanTypeName($0.name) }).joinWithSeparator("")

            return method + urlPathParts + "By" + pathStr
        } else {
            return method + urlPathParts
        }
    }

    private var splitPath: [String] {
        return path.characters.split { $0 == "/" }.map(String.init)
    }

    internal var getFullPathFuntionName: String {
        let method = self.method.rawValue.lowercaseString

        if pathParams.count > 0 {
            let pathStr = (pathParams.map { PoetUtil.cleanTypeName($0.name) }).joinWithSeparator("")
            return method + "By" + pathStr + "Url"
        } else {
            return method + "PathUrl"
        }
    }
}
