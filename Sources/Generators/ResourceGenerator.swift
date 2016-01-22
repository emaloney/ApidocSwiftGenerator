//
//  ResourceGenerator.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/21/16.
//
//

import Foundation
import SwiftPoet

public struct ResourceGenerator: Generator {
    public static var defaultTypeAliases: [(String, String)] {
        return [
            ("MetadataType"           , "DelegateTransactionType.MetadataType"),
            ("Result"                 , "TransactionResult<DataType, MetadataType>"),
            ("Callback"               , "(Result) -> Void"),
            ("DelegateTransactionType", "ApiDocDictionaryTransaction")]
    }
    public typealias ResultType = [Apidoc.FileName : ClassSpec]?

    public static func generate(service: Service) -> ResultType {

        return service.resources?.reduce([String : ClassSpec]()) { dict, resource in
            return resource.operations.reduce(dict) { (var dict, operation) in




                let classBuilder = ClassSpec.builder(resource.cleanTypeName(operation))
                    .addModifier(.Public)
                    .addSuperType(TypeName(keyword: "DelegatingDataTransaction"))
                    .addImport("GiltDataLoading")
                    .addDescription(StringUtil.concat(resource.description, right: operation.description))
                    .addFieldSpecs(ResourceGenerator.typealiasFields(operation.responses))
                    .addFieldSpecs(ResourceGenerator.transactionFieldSpecs())
                    .addMethodSpec(ResourceGenerator.getByUrlFunction(operation, resource: resource, service: service))


                dict[resource.cleanTypeName(operation)] = classBuilder.build()
                return dict
            }
        }
    }



    static func typealiasFields(resources: [Response]?) -> [FieldSpec] {
        let responseOption = (resources?.filter { r in
            if let int = r.code as? Int {
                return int == 200 || int == 201 || int == 204
            } else if let defaultCode = r.code as? ResponseCodeOption {
                return defaultCode == ResponseCodeOption.Default
            }
            return false
        })?.first

        guard let response = responseOption else {
            fatalError()
        }

        var typeAliases = ResourceGenerator.defaultTypeAliases
        typeAliases.append(("DataType", PoetUtil.cleanTypeName(response.type)))

        return typeAliases.map { ta in
            FieldSpec.builder(ta.0, construct: Construct.TypeAlias)
                .addInitializer(CodeBlock.builder().addLiteral(ta.1).build())
                .addModifier(.Public)
                .build()
        }
    }

    static func transactionFieldSpecs() -> [FieldSpec] {
        var result = [FieldSpec]()

        let delegate = FieldSpec.builder("delegateTransaction", type: TypeName(keyword: "DelegateTransactionType?"), construct: Construct.MutableParam)
            .addInitializer(CodeBlock.builder().addLiteral("return innerTransaction").build())
            .addModifier(.Public)
            .build()

        result.append(delegate)

        let inner = FieldSpec.builder("innerTransaction", type: TypeName(keyword: "DelegateTransactionType?"), construct: Construct.Field)
            .addModifier(.Private)
            .build()

        result.append(inner)

        return result
    }

    /*
    private static func getBaseUrl(checkoutGuid: NSUUID) -> String {
        return ApplicationName.baseUrl + checkoutGuid.UUIDString + "order/shipping_address"
    }

    */
    private static func getBaseUrlFn(operation: Operation, resource: Resource, service: Service) {
        // \(PoetUtil.cleanTypeName(service.name)).baseUrl
    }

    /*
    private static func getUrl(guid: NSUUID, queryParams: [String : AnyObject?]?) throws -> NSURL {
        let urlString: String
        let baseUrlString = CheckoutSessionGetByGuid.getBaseUrl(guid)
        let queryParamStrings: [String]? = queryParams?.flatMap { k, v in
            if (v != nil) {
                return "\(k):\(v)"
            }
            return nil
        }
        if queryParamStrings?.count > 0 {
            urlString = baseUrlString + "?" + queryParamStrings!.joinWithSeparator("&")
        } else {
            urlString = baseUrlString
        }

        guard let url = NSURL(string: urlString) else {
            throw DataTransactionError.InvalidURL(urlString)
        }
        return url
    }
    */
    private static func getByUrlFunction(operation: Operation, resource: Resource, service: Service) -> MethodSpec {
        let mb = MethodSpec.builder("getUrl")
            .addParameters((operation.pathParams.map { parameter in
                return ParameterSpec.builder(parameter.cammelCaseName, type: TypeName(keyword: parameter.type, optional: !parameter.required)).addDescription(parameter.description).build()
                }))
            .canThrowError()
            .addModifiers([.Private, .Static])
            .addReturnType(TypeName(keyword: "NSURL"))

        let cb = CodeBlock.builder()

        cb.addCodeLine("let urlString: String").addEmitObject(.NewLine)

        // Calling functions with an unknown number of params is a pain :( . Can probably find a cleaner way
        cb.addCodeLine("let baseUrlString = \(resource.cleanTypeName(operation)).getBaseUrl(" +
            (operation.pathParams.map { param in
                return "\(param.cammelCaseName): \(param.cleanTypeName)"
                }).joinWithSeparator(", ")
            + ")"
        ).addEmitObject(.NewLine)

        cb.addCodeLine("let queryParamStrings: [String]? = queryParams?.flatMap")
        cb.addEmitObjects((ControlFlow.closureControlFlow("k, v", canThrow: false, returnType: nil) {
            let cb = CodeBlock.builder()
            let left = CodeBlock.builder().addLiteral("v").build()
            let right = CodeBlock.builder().addLiteral("nil").build()
            cb.addCodeBlock(ControlFlow.ifControlFlow(ComparisonList(lhs: left, comparator: .NotEquals, rhs: right)) {
                return CodeBlock.builder().addLiteral("return \"\\(k):\\(v)\"").build()
            })
            return cb.addCodeLine("return nil").build()
        }).emittableObjects).addEmitObject(.NewLine)

        let leftIf = CodeBlock.builder().addLiteral("queryParamStrings?.count").build()
        let rightIf = CodeBlock.builder().addLiteral("0").build()
        cb.addCodeBlock(ControlFlow.ifControlFlow(ComparisonList(lhs: leftIf, comparator: .GreaterThan, rhs: rightIf)) {
            return CodeBlock.builder().addLiteral("urlString = baseUrlString + \"?\" + queryParamStrings!.joinWithSeparator(\"&\")").build()
        })
        cb.addCodeBlock(ControlFlow.elseControlFlow(nil) {
            return CodeBlock.builder().addLiteral("urlString = baseUrlString").build()
        }).addEmitObject(.NewLine)

        let leftGuard = CodeBlock.builder().addLiteral("let url").build()
        let rightGuard = CodeBlock.builder().addLiteral("NSURL(string: urlString)").build()

        cb.addCodeBlock(ControlFlow.guardControlFlow(ComparisonList(lhs: leftGuard, comparator: .OptionalCheck, rhs: rightGuard)) {
            return CodeBlock.builder().addLiteral("throw DataTransactionError.InvalidURL(urlString)").build()
        }).addEmitObject(.NewLine)

        cb.addCodeLine("return url")

        mb.addCode(cb.build())
        return mb.build()
    }
}
