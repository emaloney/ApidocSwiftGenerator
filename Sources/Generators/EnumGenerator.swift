//
//  EnumGenerator.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/8/16.
//
//

import SwiftPoet

public struct EnumGenerator: Generator {

    public typealias ResultType = [Apidoc.FileName : EnumSpec]?

    public static func generate(service: Service) -> ResultType {
        return service.enums?.reduce([String : EnumSpec]()) { (var dict, e) in
            let eb = EnumSpec.builder(e.name)
                .addSuperType(TypeName.StringType)
                .addModifier(.Public)
                .addDescription(e.deprecation)
                .addFieldSpecs(
                    e.values.map { value in
                        return FieldSpec.builder(value.name)
                            .addInitializer(CodeBlock.builder().addEmitObject(.EscapedString, any: value.name).build())
                            .addDescription(value.deprecation)
                            .build()
                    }
            )
            dict[PoetUtil.cleanCammelCaseString(e.name)] = eb.build()
            return dict
        }
    }
}
