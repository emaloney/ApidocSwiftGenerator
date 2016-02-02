//
//  SimpleSwiftType.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/29/16.
//
//

import Foundation
import SwiftPoet

// Maps Apidoc types to swift types
internal indirect enum SimpleSwiftType {
    case Boolean
    case DateISO8601
    case DateTimeISO8601
    case Decimal
    case Double
    case Integer
    case Long
    case Object
    case SwiftString
    case Unit
    case UUID
    case Dictionary(SwiftType, SwiftType)
    case Array(SwiftType)
    case ServiceDefinedType(String) // typeName
    case ImportedType(Namespace, String) // Namespace, typeName
    case Undefined(String)

    internal init(apidocType: String, service: Service?) {
        if SimpleSwiftType.isDictionary(apidocType) {
            let endIndex = apidocType.rangeOfString("]")!.startIndex
            let startIndex = apidocType.rangeOfString("[")!.endIndex
            let innerTypeStr = apidocType.substringWithRange(Range(start: startIndex, end: endIndex))

            self = .Dictionary(SwiftType.StringType, SwiftType(apidocType: innerTypeStr, service: service, required: !SimpleSwiftType.isOptional(innerTypeStr)))
        }
        else if SimpleSwiftType.isArray(apidocType) {
            let chars = apidocType.characters
            var range = Range(start: chars.startIndex.successor(), end: chars.endIndex.predecessor())
            range.endIndex = chars.endIndex.predecessor()

            let innerType = apidocType.substringWithRange(range)

            self = .Array(SwiftType(apidocType: innerType, service: service, required: !SimpleSwiftType.isOptional(innerType)))
        } else {
            switch apidocType {
            case "boolean": self = .Boolean; break;
            case "date-iso8601": self = .DateISO8601; break;
            case "date-time-iso8601": self = .DateTimeISO8601; break;
            case "decimal": self = .Decimal; break;
            case "double": self = .Double; break;
            case "integer": self = .Integer; break;
            case "long": self = .Long; break;
            case "object": self = .Object; break;
            case "string": self = .SwiftString; break;
            case "unit": self = .Unit; break;
            case "uuid": self = .UUID; break;
            default:
                if let (namespace, name) = SimpleSwiftType.getImportedNamespace(apidocType, imports: service?.imports) {
                    self = .ImportedType(namespace, name)
                } else if service?.contains(apidocType) == true {
                    self = .ServiceDefinedType(apidocType)
                } else {
                    self = .Undefined(apidocType)
                }
            }
        }
    }

    internal var swiftTypeString: String {
        switch self {
        case .Dictionary(let left, let right):
            return "[\(left.swiftTypeString) : \(right.swiftTypeString)]"
        case .Array(let inner):
            return "[\(inner.swiftTypeString)]"
        case .ImportedType(_, let name):
            return PoetUtil.cleanTypeName(name)
        case .ServiceDefinedType(let name):
            return PoetUtil.cleanTypeName(name)
        case .Unit:
            return "Void"
        case .Object:
            return "[String : AnyObject]"
        default:
            switch self.swiftType {
            case .Some(let type): return "\(type)"
            case .None: fatalError()
            }
        }
    }

    private var swiftType: Any? {
        switch self {
        case .Boolean: return Bool.self
        case .DateISO8601: return NSDate.self
        case .DateTimeISO8601: return NSDate.self
        case .Decimal: return Double.self
        case .Double: return Double.self
        case .Integer: return Int.self
        case .Long: return Int.self
        case .SwiftString: return String.self
        case .UUID: return NSUUID.self
        default: return nil
        }
    }

    private static func isOptional(keyword: String) -> Bool {
        guard let last = keyword.characters.last else { return false }
        return last == "?"
    }

    private static func isArray(keyword: String) -> Bool {
        var arrayMatch: NSRegularExpression?
        let range = NSRange(location: 0, length: keyword.characters.count)

        do {
            arrayMatch = try NSRegularExpression(pattern: "^\\[.+\\]\\??$", options: .CaseInsensitive)
        } catch {
            arrayMatch = nil // this should never happen
        }

        return arrayMatch?.numberOfMatchesInString(keyword, options: .Anchored, range: range) == 1
    }

    private static func isDictionary(keyword: String) -> Bool {
        var dictionaryMatch: NSRegularExpression?
        let range = NSRange(location: 0, length: keyword.characters.count)

        do {
            dictionaryMatch = try NSRegularExpression(pattern: "^map\\[.+\\]$", options: NSRegularExpressionOptions.CaseInsensitive)
        } catch {
            dictionaryMatch = nil // this should never happen
        }

        return dictionaryMatch?.numberOfMatchesInString(keyword, options: .Anchored, range: range) == 1
    }

    private static func getImportedNamespace(apidocType: String, imports: [Import]?) -> (Namespace, String)? {
        var result: (Namespace, String)? = nil
        imports?.forEach { imprt in
            do {
                let regex = try NSRegularExpression(pattern: imprt.namespace, options: NSRegularExpressionOptions.CaseInsensitive)
                if regex.matchesInString(apidocType, options: [], range: NSMakeRange(0, apidocType.characters.count)).count > 0 {
                    let name = apidocType.componentsSeparatedByString(".").last!
                    result = (Namespace(namespace: imprt.namespace, applicationKey: imprt.application.key), PoetUtil.cleanTypeName(name))
                }
            } catch {
                result = nil
            }
        }
        return result
    }
}