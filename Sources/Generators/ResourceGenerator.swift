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
            ("Callback"               , "(Result) -> Void")]
    }
    public typealias ResultType = [PoetFile]?

    public static func generate(service: Service) -> ResultType {

        return service.resources?.reduce([PoetFile]()) { (var list, resource) in
            let transactionList: [PoetFile] = resource.operations.map { operation in
                let classBuilder = ClassSpec.builder(resource.cleanTypeName(operation))
                    .addFramework(service.name)
                    .addModifier(.Public)
                    .addSuperType(TypeName(keyword: "DelegatingDataTransaction"))
                    .addImports(["Foundation", "CleanroomConcurrency", "CleanroomDataTransactions"])
                    .addDescription(StringUtil.concat(resource.description, right: operation.description))
                    .addFieldSpecs(ResourceGenerator.typealiasFields(operation, service: service))
                    .addFieldSpecs(ResourceGenerator.transactionFields())
                    .addMethodSpec(ResourceGenerator.getInitFn(operation, resource: resource, service: service))
                    .addMethodSpec(ResourceGenerator.getBaseUrlFn(operation, resource: resource, service: service))
                    .addMethodSpec(ResourceGenerator.getUrlFn(operation, resource: resource, service: service))
                    .addMethodSpec(ResourceGenerator.executeTransactionFn(operation, service: service))

                return classBuilder.build().toFile()
            }
            list.appendContentsOf(transactionList)
            return list
        }
    }

    static func typealiasFields(operation: Operation, service: Service) -> [FieldSpec] {
        guard let successReturnType = operation.successReturnType,
            let swiftType = SwiftType(apidocType: successReturnType, imports: service.imports) else {
            fatalError()
        }

        var typeAliases = ResourceGenerator.defaultTypeAliases
        typeAliases.append(("DataType", swiftType.swiftTypeString))
        typeAliases.append(("DelegateTransactionType", ResourceGenerator.getTransationType(swiftType)))

        return typeAliases.map { ta in
            FieldSpec.builder(ta.0, construct: Construct.TypeAlias)
                .addInitializer(CodeBlock.builder().addLiteral(ta.1).build())
                .addModifier(.Public)
                .build()
        }
    }

    private static func getTransationType(type: SwiftType) -> String {
        switch type {
        case .Unit:
            return "ApiDocOptionalDictionaryTransaction"
        case .Array:
            return "ApiDocArrayTransaction"
        default:
            return "ApiDocDictionaryTransaction"
        }
    }

    static func transactionFields() -> [FieldSpec] {
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
    public init(guid: NSUUID, address: Address, refresh: Bool?, ipAddress: String, origin: String) throws {
        let queryParams: [String : AnyObject?] = [
            "refresh" : refresh,
            "ipAppress" : ipAddress,
            "origin" : origin]

        do {
            let request = NSMutableURLRequest(URL: try CheckoutSessionGetByGuid.getUrl(checkoutGuid, queryParams: queryParams))
            request.HTTPMethod = "PUT"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            let binaryData: NSData?
            switch address.toBinaryData() {
            case .Succeeded(let data):
                binaryData = data
            case .Failed(let error):
                throw error
            }

            self.innerTransaction = ApiDocDictionaryTransaction(request: request, uploadData: binaryData)
        } catch {
            self.innerTransaction = nil
            throw error
        }
    }
    */
    private static func getInitFn(operation: Operation, resource: Resource, service: Service) -> MethodSpec {
        let mb = MethodSpec.builder("init")
            .addModifier(.Public)
            .canThrowError()
            .addParameters(operation.parameters.map { param in
                return ParameterSpec.builder(param.name, type: TypeName(keyword: SwiftType(apidocType: param.type, imports: service.imports)!.swiftTypeString, optional: !param.required))
                    .addDescription(param.description)
                    .build()
            })

        if let body = operation.body {
            mb.addParameter(ParameterSpec.builder("body", type: TypeName(keyword: body.type))
                .addDescription(body.description).build())
        }

        let cb = CodeBlock.builder()
        let swiftType = SwiftType(apidocType: operation.successReturnType!, imports: service.imports)!

        if operation.queryParams.count > 0 {
            cb.addCodeLine("let queryParams: [String : AnyObject?]? = [")
            cb.addEmitObject(.IncreaseIndentation)
            cb.addCodeBlock(CodeBlock.builder().addLiteral((operation.queryParams.map { param in
                let swiftType = SwiftType(apidocType: param.type, imports: service.imports)!
                let stringCleaner = ".stringByReplacingOccurrencesOfString(\" \", withString: \"+\")"
                let cleanStringFn: String
                if swiftType.swiftTypeString == "String" && param.required {
                    cleanStringFn = stringCleaner
                } else if swiftType.swiftTypeString == "String" {
                    cleanStringFn = "?" + stringCleaner
                } else {
                    cleanStringFn = ""
                }
                return "\"\(param.cammelCaseName)\" : \(swiftType.toString(param.cammelCaseName, optional: !param.required))\(cleanStringFn)"
            }).joinWithSeparator(", ")).build())
            cb.addLiteral("]")
            cb.addEmitObject(.DecreaseIndentation)
            cb.addEmitObject(.NewLine)
        } else {
            cb.addCodeLine("let queryParams: [String : AnyObject?]? = nil")
        }

        cb.addCodeBlock(ControlFlow.doCatchControlFlow({
            let cb = CodeBlock.builder()
            cb.addLiteral("let request = NSMutableURLRequest(URL: try")
            cb.addLiteral("\(resource.cleanTypeName(operation)).getUrl(")
            for (index, param) in operation.pathParams.enumerate() {
                if index == 0 {
                    cb.addLiteral("\(param.cammelCaseName),")
                } else {
                    cb.addLiteral("\(param.cammelCaseName): \(param.cammelCaseName),")
                }
            }
            if operation.pathParams.isEmpty {
                cb.addLiteral("queryParams))")
            } else {
                cb.addLiteral("queryParams : queryParams))")
            }
            cb.addCodeLine("request.HTTPMethod = \"\(operation.method.rawValue.uppercaseString)\"")
            cb.addCodeLine("request.addValue(\"application/json\", forHTTPHeaderField: \"Content-Type\")")
            cb.addEmitObject(.NewLine)

            if let _ = operation.body {
                cb.addCodeLine("let binaryData: NSData?")
                cb.addCodeBlock(ControlFlow.switchControlFlow("body.toBinaryData()", cases: [
                    (".Succeeded(let data)", CodeBlock.builder().addLiteral("binaryData = data").build()),
                    (".Failed(let error)", CodeBlock.builder().addLiteral("throw error").build())
                ]))

                cb.addCodeLine("self.innerTransaction = \(ResourceGenerator.getTransationType(swiftType))(request: request, uploadData: binaryData)")

            } else {
                cb.addCodeLine("self.innerTransaction = \(ResourceGenerator.getTransationType(swiftType))(request: request, uploadData: nil)")
            }
            return cb.build()

        }) {
            return CodeBlock.builder()
                .addCodeLine("self.innerTransaction = nil")
                .addCodeLine("throw error")
                .build()
        })

        return mb.addCode(cb.build()).build()
    }

    /*
    private static func getBaseUrl(pathParams...) -> String {
        return ApplicationName.baseUrl + "/part/of/route/\(pathParam1)/more/route/\(pathParam2)"
    }
    stringByReplacingOccurrencesOfString
    */
    private static func getBaseUrlFn(operation: Operation, resource: Resource, service: Service) -> MethodSpec {
        let mb = MethodSpec.builder("getBaseUrl")
            .addModifiers([.Private, .Static])
            .addParameters(operation.pathParams.map { param in
                return ParameterSpec.builder(param.name, type: TypeName(keyword: SwiftType(apidocType: param.type, imports: service.imports)!.swiftTypeString, optional: !param.required))
                    .addDescription(param.description)
                    .build()
            })
            .addReturnType(TypeName.StringType)

        var pathString = operation.path
        operation.pathParams.forEach { param in
            let paramTypeToString: String = SwiftType(apidocType: param.type, imports: service.imports)!.toString(param.cammelCaseName)
            pathString = pathString.stringByReplacingOccurrencesOfString(":\(param.name)", withString: "\\(\(paramTypeToString))")
        }

        mb.addCode(CodeBlock.builder().addLiteral("return \(service.cleanTypeName).baseUrl + \"\(pathString)\"").build())

        return mb.build()
    }

    /*
    private static func getUrl(pathParam: PathParamType, queryParams: [String : AnyObject?]?) throws -> NSURL {
        let urlString: String
        let baseUrlString = CheckoutSessionGetByGuid.getBaseUrl(guid)
        let queryParamStrings: [String]? = queryParams?.flatMap { k, v in
            if (v != nil) {
                return "\(k)=\(v!))"
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
    private static func getUrlFn(operation: Operation, resource: Resource, service: Service) -> MethodSpec {
        let mb = MethodSpec.builder("getUrl")
            .addParameters((operation.pathParams.map { parameter in
                return ParameterSpec.builder(parameter.name, type: TypeName(keyword: SwiftType(apidocType: parameter.type, imports: service.imports)!.swiftTypeString, optional: !parameter.required)).addDescription(parameter.description).build()
                }))
            .addParameter(ParameterSpec.builder("queryParams", type: TypeName(keyword: "[String : AnyObject?]?")).build())
            .canThrowError()
            .addModifiers([.Private, .Static])
            .addReturnType(TypeName(keyword: "NSURL"))

        let cb = CodeBlock.builder()

        cb.addCodeLine("let urlString: String").addEmitObject(.NewLine)

        // Calling functions with an unknown number of params is a pain :( . Can probably find a cleaner way
        cb.addCodeLine("let baseUrlString = \(resource.cleanTypeName(operation)).getBaseUrl(")
        for (index, param) in operation.pathParams.enumerate() {
            if index == 0 && operation.pathParams.count > 1 {
                cb.addLiteral("\(param.cammelCaseName),")
            } else if index == 0 {
                cb.addLiteral("\(param.cammelCaseName)")
            }else if index == operation.pathParams.count - 1 {
                cb.addLiteral("\(param.cammelCaseName): \(param.cammelCaseName)")
            } else {
                cb.addLiteral("\(param.cammelCaseName): \(param.cammelCaseName),")
            }
        }
        cb.addLiteral(")")
        cb.addEmitObject(.NewLine)
        cb.addCodeLine("let queryParamStrings: [String]? = queryParams?.flatMap")
        cb.addEmitObjects((ControlFlow.closureControlFlow("k, v", canThrow: false, returnType: TypeName.StringOptional) {
            let cb = CodeBlock.builder()
            let left = CodeBlock.builder().addLiteral("v").build()
            let right = CodeBlock.builder().addLiteral("nil").build()
            cb.addCodeBlock(ControlFlow.ifControlFlow(ComparisonList(lhs: left, comparator: .NotEquals, rhs: right)) {
                return CodeBlock.builder().addLiteral("return \"\\(k)=\\(v!)\"").build()
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

    /*
    public func executeTransaction(completion: Callback) {
        innerTransaction?.executeTransaction() { result in
            switch result {
            case .Failed(let error):
                completion(.Failed(error))

            case .Succeeded(let payload, let meta):
                async {
                    do {
                        let model = try CheckoutSession(jsonData: payload) ********************
                        completion(.Succeeded(model, meta))
                    }
                    catch {
                        completion(.Failed(.wrap(error)))
                    }
                }
            }
        }
    }
    */
    private static func executeTransactionFn(operation: Operation, service: Service) -> MethodSpec {
        let successCB = CodeBlock.builder()
        let swiftType = SwiftType(apidocType: operation.successReturnType!, imports: service.imports)!
        var field = Field(name: "model", type: operation.successReturnType!, description: nil, deprecation: nil, _default: nil, required: true, minimum: nil, maximum: nil, example: nil)

        if swiftType.swiftTypeString == "Void" {
            successCB.addLiteral("// Take no action")
            successCB.addCodeLine("return")
        } else {
            let jsonParseCode: CodeBlock

            switch swiftType {
            case .Array(let innerType):
                field = field.clone(withTypeName: innerType.swiftTypeString)

                jsonParseCode = CodeBlock.builder().addLiteral("let model = try payload.map")
                    .addEmitObjects((ControlFlow.closureControlFlow("payload", canThrow: true, returnType: field.cleanTypeName) {
                        let cb = CodeBlock.builder()
                        let left = CodeBlock.builder().addLiteral("let payload").build()
                        let right = CodeBlock.builder().addLiteral("payload as? NSDictionary").build()
                        cb.addEmitObjects((ControlFlow.guardControlFlow(ComparisonList(lhs: left, comparator: .OptionalCheck, rhs: right)) {
                            return CodeBlock.builder().addLiteral("throw DataTransactionError.DataFormatError(\"Invalid conversion from array to [dictionary]\")").build()
                        }).emittableObjects)
                        cb.addEmitObjects(CodeBlock.builder()
                                .addEmitObjects(ModelGenerator.generateParseModelJson(field, service: service, rootJson: true).emittableObjects)
                                .addCodeLine("return model")
                                .build().emittableObjects)

                        return cb.build()
                    }).emittableObjects)
                    .build()
            default:
                jsonParseCode = FieldGenerator.generateJsonParse(field, service: service, rootJson: true)
            }

            successCB
                .addLiteral("async")
                .addEmitObject(.BeginStatement)
                .addCodeBlock(ControlFlow.doCatchControlFlow({
                    return CodeBlock.builder()
                        .addCodeBlock(jsonParseCode)
                        .addCodeLine("completion(.Succeeded(model, meta))").build()
                    }) {
                        return CodeBlock.builder().addLiteral("completion(.Failed(.wrap(error)))").build()
                    })
                .addEmitObject(.EndStatement)
        }


        let cb = CodeBlock.builder()
            .addLiteral("innerTransaction?.executeTransaction()")
            .addEmitObjects(ControlFlow.closureControlFlow("result", canThrow: false, returnType: nil) {
                return ControlFlow.switchControlFlow("result", cases: [
                    (".Failed(let error)", CodeBlock.builder().addLiteral("completion(.Failed(error))").build()),
                    (".Succeeded(let payload, let meta)", successCB.build())])
                }.emittableObjects).build()

        return MethodSpec.builder("executeTransaction")
            .addParameter(ParameterSpec.builder("completion", type: TypeName(keyword: "Callback")).build())
            .addModifier(.Public)
            .addCode(cb)
            .build()
    }
}
