//
//  ResourceGenerator.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/21/16.
//
//

import Foundation
import SwiftPoet

internal struct ResourceGenerator: Generator {
    internal static var defaultTypeAliases: [(String, String)] {
        return [
            ("MetadataType", "WrappedTransactionType.MetadataType"),
            ("Result"      , "TransactionResult<DataType, MetadataType>"),
            ("Callback"    , "(Result) -> Void")]
    }
    internal typealias ResultType = [PoetFile]?

    internal static func generate(service: Service) -> ResultType {

        return service.resources?.reduce([PoetFile]()) { (var list, resource) in
            let transactionList: [PoetFile] = resource.operations.map { operation in
                let classBuilder = ClassSpec.builder(resource.capitalizedName(operation))
                    .addFramework(service.name)
                    .addModifier(.Public)
                    .addSuperType(TypeName(keyword: "WrappingDataTransaction"))
                    .addImports(["CleanroomConcurrency", "CleanroomDataTransactions", "Foundation"])
                    .addDescription(resource.description(operation))
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
        guard let successReturnType = operation.successReturnType else {
            fatalError()
        }

        let swiftType = SwiftType(apidocType: successReturnType, service: service)

        var typeAliases = ResourceGenerator.defaultTypeAliases
        typeAliases.append(("DataType", swiftType.swiftTypeString))
        typeAliases.append(("WrappedTransactionType", ResourceGenerator.getTransationType(swiftType)))

        return typeAliases.map { ta in
            FieldSpec.builder(ta.0, construct: Construct.TypeAlias)
                .addInitializer(CodeBlock.builder().addLiteral(ta.1).build())
                .addModifier(.Public)
                .build()
        }
    }

    private static func getTransationType(swiftType: SwiftType) -> String {
        switch swiftType.type {
        case .Unit:
            return "ApiDocOptionalDictionaryTransaction"
        case .Array:
            return "ApiDocArrayTransaction"
        case .SwiftString, .Integer, .Long, .Double, .Boolean, .Decimal:
            return "ApiDocTransaction<\(swiftType.swiftTypeString)>"
        default:
            return "ApiDocDictionaryTransaction"
        }
    }

    static func transactionFields() -> [FieldSpec] {
        var result = [FieldSpec]()

        let inner = FieldSpec.builder("innerTransaction", type: TypeName(keyword: "WrappedTransactionType?"), construct: Construct.Field)
            .addModifier(.Public)
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
                return ParameterSpec.builder(param.name, type: TypeName(keyword: SwiftType(apidocType: param.type, service: service, required: param.required).swiftTypeString, optional: !param.required))
                    .addDescription(param.description)
                    .build()
            })

        if let body = operation.body {
            mb.addParameter(ParameterSpec.builder("body", type: TypeName(keyword: body.type))
                .addDescription(body.description).build())
        }

        let cb = CodeBlock.builder()
        let swiftType = SwiftType(apidocType: operation.successReturnType!, service: service)

        if operation.queryParams.count > 0 {
            cb.addCodeLine("let queryParams: [String : AnyObject?]? = [")
            cb.addEmitObject(.IncreaseIndentation)
            cb.addCodeBlock(CodeBlock.builder().addLiteral((operation.queryParams.map { param in
                let swiftType = SwiftType(apidocType: param.type, service: service, required: param.required)
                let stringCleaner = ".stringByReplacingOccurrencesOfString(\" \", withString: \"+\")"
                let cleanStringFn: String
                if swiftType.swiftTypeString == "String" && param.required {
                    cleanStringFn = stringCleaner
                } else if swiftType.swiftTypeString == "String" {
                    cleanStringFn = "?" + stringCleaner
                } else {
                    cleanStringFn = ""
                }
                return "\"\(param.cammelCaseName)\" : \(swiftType.toString(param.cammelCaseName))\(cleanStringFn)"
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
            cb.addLiteral("\(resource.capitalizedName(operation)).getUrl(")
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

            // No JSON header if no json body expected.
            if let _ = operation.body {
                cb.addCodeLine("request.addValue(\"application/json\", forHTTPHeaderField: \"Content-Type\")")
            }

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
                return ParameterSpec.builder(param.name, type: TypeName(keyword: SwiftType(apidocType: param.type, service: service).swiftTypeString, optional: !param.required))
                    .addDescription(param.description)
                    .build()
            })
            .addReturnType(TypeName.StringType)

        var pathString = operation.path
        operation.pathParams.forEach { param in
            let paramTypeToString: String = SwiftType(apidocType: param.type, service: service).toString(param.cammelCaseName)
            pathString = pathString.stringByReplacingOccurrencesOfString(":\(param.name)", withString: "\\(\(paramTypeToString))")
        }

        mb.addCode(CodeBlock.builder().addLiteral("return \(service.capitalizedName).baseUrl + \"\(pathString)\"").build())

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
                return ParameterSpec.builder(parameter.name, type: TypeName(keyword: SwiftType(apidocType: parameter.type, service: service).swiftTypeString, optional: !parameter.required)).addDescription(parameter.description).build()
                }))
            .addParameter(ParameterSpec.builder("queryParams", type: TypeName(keyword: "[String : AnyObject?]?")).build())
            .canThrowError()
            .addModifiers([.Private, .Static])
            .addReturnType(TypeName(keyword: "NSURL"))

        let cb = CodeBlock.builder()

        cb.addCodeLine("let urlString: String").addEmitObject(.NewLine)

        // Calling functions with an unknown number of params is a pain :( . Can probably find a cleaner way
        cb.addCodeLine("let baseUrlString = \(resource.capitalizedName(operation)).getBaseUrl(")
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
                // Void
                // Take not action
                return
    
                // SimpleType
                completion(.Succeeded(payload, meta))

                // Array OR Model
                async {
                    do {
                        // Array
                        let model = try payload.map { payload in
                            guard let payload = payoad as? NSDictionary else {
                                DataTransactionError.DataFormatError("Error creating model. Expected an NSDictionary")")
                            }
                            let model = try TypeName(payload: payload)
                            return model
                        }
                        completion(.Succeeded(model, meta))
                        
                        // Model
                        let model = try TypeName(payload: payload)
                        completion(.Succeeded(model, meta))
     
                        // Dictionary
                        see DictionaryGenerator.jsonParseCodeBlockRequired
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
        var jsonParseCode: CodeBlock? = nil
        let swiftType = SwiftType(apidocType: operation.successReturnType!, service: service)
        var isUnit = false

        switch swiftType.type {
        case .Unit:
            isUnit = true
            successCB
                .addLiteral("// Take no action")
                .addCodeLine("return")
            break
        case .SwiftString, .Integer, .Long, .Double, .Boolean, .Decimal:
            successCB.addLiteral("completion(.Succeeded(payload, meta))")
            break

        case .Dictionary(_, let valueType):
            jsonParseCode = CodeBlock.builder()
                .addCodeBlock(DictionaryGenerator.jsonParseCodeBlockRequired("model", valueType: valueType, dictionaryName: "payload", service: service))
                .addCodeLine("completion(.Succeeded(model, meta))")
                .build()

        case .Array(let typeName):
            jsonParseCode = CodeBlock.builder()
                .addLiteral("let model = try payload.map")
                .addCodeBlock(ControlFlow.closureControlFlow("payload", canThrow: true, returnType: typeName.swiftTypeString) {
                    return CodeBlock.builder()
                        .addCodeBlock(ControlFlow.guardControlFlow(ComparisonList(lhs: "let payload".toCodeBlock(), comparator: .OptionalCheck, rhs: "payload as? NSDictionary".toCodeBlock())) {
                            return "throw DataTransactionError.DataFormatError(\"Error creating model. Expected an NSDictionary\")".toCodeBlock()
                        })
                        .addCodeBlock(CodeBlock.builder()
                            .addCodeBlock(ModelGenerator.toModelCodeBlock("model", typeName: typeName.swiftTypeString, jsonParamName: "payload", service: service, initalize: true))
                            .addCodeLine("return model")
                            .build())
                    .build()
                })
                .addCodeLine("completion(.Succeeded(model, meta))")
                .build()

        case .ServiceDefinedType(let typeName):
            let cleanTypeName = PoetUtil.cleanTypeName(typeName)
            jsonParseCode = CodeBlock.builder()
                .addCodeBlock(ModelGenerator.toModelCodeBlock("model", typeName: cleanTypeName, jsonParamName: "payload", service: service, initalize: true))
                .addCodeLine("completion(.Succeeded(model, meta))")
                .build()
        case .ImportedType(_, let typeName):
            let cleanTypeName = PoetUtil.cleanTypeName(typeName)
            jsonParseCode = CodeBlock.builder()
                .addCodeBlock(ModelGenerator.toModelCodeBlock("model", typeName: cleanTypeName, jsonParamName: "payload", service: service, initalize: true))
                .addCodeLine("completion(.Succeeded(model, meta))")
                .build()
        default:
            fatalError()
        }

        if let jsonParseCode = jsonParseCode {
            successCB
                .addLiteral("async")
                .addEmitObject(.BeginStatement)
                .addCodeBlock(ControlFlow.doCatchControlFlow({
                    return jsonParseCode
                }) {
                    return "completion(.Failed(.wrap(error)))".toCodeBlock()
                })
                .addEmitObject(.EndStatement)
        }

        let successCase = isUnit ? ".Succeeded" : ".Succeeded(let payload, let meta)"

        let cb = CodeBlock.builder()
            .addLiteral("innerTransaction?.executeTransaction()")
            .addEmitObjects(ControlFlow.closureControlFlow("result", canThrow: false, returnType: nil) {
                return ControlFlow.switchControlFlow("result", cases: [
                    (".Failed(let error)", "completion(.Failed(error))".toCodeBlock()),
                    (successCase, successCB.build())])
                }.emittableObjects).build()

        return MethodSpec.builder("executeTransaction")
            .addParameter(ParameterSpec.builder("completion", type: TypeName(keyword: "Callback")).build())
            .addModifier(.Public)
            .addCode(cb)
            .build()
    }
}
