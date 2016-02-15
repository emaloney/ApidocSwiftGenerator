//
//  JSONEncoder.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 8/13/15.
//  Copyright © 2015 Gilt Groupe. All rights reserved.
//

import Foundation

public enum ApidocJSONEncoderResult<T> {
    case Succeeded(T)
    case Failed(ErrorType)
}

internal protocol BinaryDataModel {
    func toBinaryData () -> BinaryEncoderResult<NSData>
}

extension BinaryDataModel where Self : JSONDataModel {
    internal func toBinaryData () -> BinaryEncoderResult<NSData> {

        switch self.toJSON() {
        case .Succeeded(let json):
            if NSJSONSerialization.isValidJSONObject(json) {
                do {
                    let data = try NSJSONSerialization.dataWithJSONObject(json, options: NSJSONWritingOptions(rawValue: 0))
                    return .Succeeded(data)
                } catch {
                    return .Failed(error)
                }
            } else {
                return .Failed(EncoderErrorType.InvalidJson)
            }
        case .Failed(let error):
            return .Failed(error)
        }
    }
}

internal enum BinaryEncoderResult<T> {
    case Succeeded(T)
    case Failed(ErrorType)
}

internal enum EncoderErrorType: ErrorType {
    case InvalidJson
}

internal protocol JSONDataModel {
    func toJSON () -> ApidocJSONEncoderResult<AnyObject>
}

extension Array where Element:JSONDataModel {
    func toJSON () -> ApidocJSONEncoderResult<[AnyObject]> {
        var result = [AnyObject]()
        for model in self {
            switch model.toJSON() {
            case .Succeeded(let json):
                result.append(json)
            case .Failed(let error):
                return .Failed(error)
            }
        }
        return .Succeeded(result)
    }
}
extension Array where Element:JSONDataModel {
    func toBinaryData () -> BinaryEncoderResult<NSData>
    {
        switch self.toJSON() {
        case .Succeeded(let json):
            if NSJSONSerialization.isValidJSONObject(json) {
                do {
                    let data = try NSJSONSerialization.dataWithJSONObject(json, options: NSJSONWritingOptions(rawValue: 0))
                    return .Succeeded(data)
                } catch {
                    return .Failed(error)
                }
            } else {
                return .Failed(EncoderErrorType.InvalidJson)
            }
        case .Failed(let error):
            return .Failed(error)
        }
    }
}

extension String {
    func toBinaryData () -> BinaryEncoderResult<NSData>
    {
        if let data = ("\"" + self + "\"").dataUsingEncoding(NSUTF8StringEncoding) {
            return BinaryEncoderResult.Succeeded(data)
        } else {
            return .Failed(EncoderErrorType.InvalidJson)
        }
    }
}
