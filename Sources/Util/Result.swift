//
//  Result.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/6/16.
//
//

import Foundation

public enum Result<DataType, Error: ErrorType> {
    case Succeeded(DataType)
    case Failed(Error)
}