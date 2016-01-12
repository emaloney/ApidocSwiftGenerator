//
//  ModelGenerator.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/12/16.
//
//

import Foundation
import SwiftPoet

public struct ModelGenerator: Generator {
    public typealias ResultType = [Apidoc.FileName : StructSpec]?

    public static func generate(service: Service) -> ResultType {
        return service.models?.reduce([String : StructSpec]()) { (var dict, m) in
            let sb = StructSpec.builder(m.name)
                .includeDefaultInit()
                .addModifier(.Public)
                .addDescription(m.description)
                .addFieldSpecs(m.fields.map { field in
                    let swiftType = SwiftType(apidocType: field.type)
                    let typeStr = swiftType!.swiftTypeString
                    let typeName = TypeName(keyword: typeStr, optional: field.required)
                    return FieldSpec.builder(field.name, type: typeName)
                        .addDescription(field.description)
                        .addModifier(.Public)
                        .build()
                    })

            dict[PoetUtil.cleanCammelCaseString(m.name)] = sb.build()
            return dict
        }
    }
}
