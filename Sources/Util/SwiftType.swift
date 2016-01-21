//
//  SwiftType.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/12/16.
//
//

import Foundation
import SwiftPoet

// Maps Apidoc types to swift types
public indirect enum SwiftType {
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
    case ExternalType(String) // typeName
    case ImportedType(Namespace, String) // Namespace, typeName

    public init?(apidocType: String, imports: [Import]?) {
        if SwiftType.isDictionary(apidocType) {
            let endIndex = apidocType.rangeOfString("]")!.startIndex
            let startIndex = apidocType.rangeOfString("[")!.endIndex
            let innerTypeStr = apidocType.substringWithRange(Range(start: startIndex, end: endIndex))

            self = .Dictionary(SwiftType(apidocType: innerTypeStr, imports: imports)!, SwiftType(apidocType: innerTypeStr, imports: imports)!)
        }
        else if SwiftType.isArray(apidocType) {
            let chars = apidocType.characters
            var range = Range(start: chars.startIndex.successor(), end: chars.endIndex.predecessor())
            range.endIndex = chars.endIndex.predecessor()

            let innerType = apidocType.substringWithRange(range)

            self = .Array(SwiftType(apidocType: innerType, imports: imports)!)
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
                if let (namespace, name) = SwiftType.getImportedNamespace(apidocType, imports: imports) {
                    self = .ImportedType(namespace, name)
                } else {
                    self = .ExternalType(apidocType)
                }
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
        case .Object: return NSDictionary.self
        case .SwiftString: return String.self
        case .Unit: return nil
        case .UUID: return NSUUID.self
        default: return nil
        }
    }

    public var swiftTypeString: String {
        switch self {
        case .Dictionary(let left, let right):
            return "[\(left.swiftTypeString) : \(right.swiftTypeString)]"
        case .Array(let inner):
            return "[\(inner.swiftTypeString)]"
        case .ImportedType(_, let name):
            return name
        case .ExternalType(let s):
            return s
        default:
            switch self.swiftType {
            case .Some(let type): return "\(type)"
            case .None: return "nil"
            }
        }
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
