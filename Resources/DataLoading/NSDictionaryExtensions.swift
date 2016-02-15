//
//  NSDictionaryExtensions.swift
//  ApidocSwiftGenerator
//
//  Created by Evan Maloney on 7/28/15.
//  Copyright © 2015 Gilt Groupe. All rights reserved.
//

import Foundation
import CleanroomDataTransactions

extension NSDictionary
{
    internal func required(key: String)
        throws
        -> Any
    {
        guard let val = self[key] else {
            throw DataTransactionError.DataFormatError("Expected to find key named \"\(key)\" containing a String value")
        }
        return val
    }

    internal func requiredGUID(key: String)
        throws
        -> NSUUID
    {
        let guidStr = try self.requiredString(key)

        guard let val = NSUUID(UUIDString: guidStr) else {
            throw DataTransactionError.DataFormatError("Expected to find key named \(key) containing a GUID value")
        }
        return val
    }

    internal func requiredBool(key: String)
        throws
        -> Bool
    {
        if let boolInt = self[key] as? Int {
            return boolInt != 0
        } else if let boolStr = self[key] as? String {
            return boolStr == "true"
        } else if let bool = self[key] as? Bool {
            return bool
        }

        throw DataTransactionError.DataFormatError("Expected to find key named \"\(key)\" containing a numberis, string, or boolean Bool value")
    }

    internal func optionalBool(key: String)
        -> Bool?
    {
        if let boolStr = self[key] as? String {
            return boolStr == "true"
        } else if let boolInt = self[key] as? Int {
            return boolInt != 0
        } else if let bool = self[key] as? Bool {
            return bool
        }
        return nil
    }

    internal func requiredInt(key: String)
        throws
        -> Int
    {
        guard let val = self[key] as? Int else {
            throw DataTransactionError.DataFormatError("Expected to find key named \"\(key)\" containing an Int value")
        }
        return val
    }

    internal func requiredDouble(key: String)
        throws
        -> Double
    {
        guard let val = self[key] as? Double else {
            throw DataTransactionError.DataFormatError("Expected to find key named \"\(key)\" containing a Double value")
        }
        return val
    }

    internal func requiredArray(key: String)
        throws
        -> NSArray
    {
        guard let val = self[key] as? NSArray else {
            throw DataTransactionError.DataFormatError("Expected to find key named \"\(key)\" containing an NSArray")
        }
        return val
    }

    internal func requiredArrayWithType<T, A: AnyObject>(key: String, transform: (A) throws -> T)
        throws
        -> [T]
    {
        let extractedArray = try self.requiredArray(key) as! [A]
        var resultArray = [T]()

        for item in extractedArray {
            resultArray.append(try transform(item))
        }

        return resultArray
    }

    internal func requiredArrayWithType<T, A: AnyObject>(key: String, optionalTransform: (A) -> T?)
        throws
        -> [T]
    {
        let extractedArray = try self.requiredArray(key) as! [A]

        return extractedArray.flatMap { item in
            return optionalTransform(item)
        }
    }

    internal func optionalArrayWithType<T, A: AnyObject>(key: String, transform: (A) throws -> T)
        throws
        -> [T]?
    {
        let extractedArray = self[key] as? [A]

        if let array = extractedArray {
            var resultArray = [T]()

            for item in array {
                resultArray.append(try transform(item))
            }

            return resultArray
        }
        return nil
    }

    internal func optionalArrayWithType<T, A: AnyObject>(key: String, optionalTransform: (A) -> T?)
        -> [T]?
    {
        let extractedArray = self[key] as? [A]
        
        return extractedArray?.flatMap { item in
            return optionalTransform(item)
        }
    }

    internal func requiredStringArray(key: String)
        throws
        -> [String]
    {
        guard let val = self[key] as? NSArray else {
            throw DataTransactionError.DataFormatError("Expected to find key named \"\(key)\" containing an NSArray")
        }
        
        var strings = [String]()
        for item in val {
            guard let str = item as? String else {
                throw DataTransactionError.DataFormatError("Expected to find string values in the array for the key named \"\(key)\".")
            }
            strings += [str]
        }
        return strings
    }
    
    internal func requiredDictionary(key: String)
        throws
        -> NSDictionary
    {
        guard let val = self[key] as? NSDictionary else {
            throw DataTransactionError.DataFormatError("Expected to find key named \"\(key)\" containing an NSDictionary")
        }
        return val
    }

    internal func requiredString(key: String)
        throws
        -> String
    {
        guard let val = self[key] as? String else {
            throw DataTransactionError.DataFormatError("Expected to find key named \"\(key)\" containing a String value")
        }
        return val
    }

    internal func requiredURL(key: String)
        throws
        -> NSURL
    {
        guard let url = NSURL(string: try requiredString(key)) else {
            throw DataTransactionError.DataFormatError("Expected the key named \"\(key)\" to contain a valid URL value")
        }
        return url
    }

    internal func requiredRFC1123Date(key: String)
        throws
        -> NSDate
    {
        let dateStr = try requiredString(key)
        
        guard let date = dateStr.asDateRFC1123() else {
            throw DataTransactionError.DataFormatError("Expected to key named \"\(key)\" to contain a date in RFC 1123 format")
        }
        
        return date
    }

    internal func requiredISO8601Date(key: String)
        throws
        -> NSDate
    {
        let dateStr = try requiredString(key)

        guard let date = dateStr.asDateISO8601() else {
            throw DataTransactionError.DataFormatError("Expected to key named \"\(key)\" to contain a date in ISO 8601 format")
        }

        return date
    }
}
