//
//  OperationExtension.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/29/16.
//
//

import Foundation
import SwiftPoet

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

    internal var capitalizedName: String {
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

    internal var successReturnType: String? {
        let returnTypeOption = (self.responses?.filter { r in
            if let int = r.code as? Int {
                return int == 200 || int == 201 || int == 204
            } else if let defaultCode = r.code as? ResponseCodeOption {
                return defaultCode == ResponseCodeOption.Default
            }
            return false
            })?.first

        guard let returnType = returnTypeOption else {
            return nil
        }
        return returnType.type
    }
}
