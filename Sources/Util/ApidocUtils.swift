//
//  ApidocRepresentation.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/29/16.
//
//

import Foundation

internal enum ApidocRepresentation: String {
    case Enum = "Enum"
    case Model = "Model"
    case Union = "Union"
    case Resource = "Resource"
}

internal enum ApidocServerError: ErrorType {
    case InvalidToken
    case MissingEmailOrPassword
    case InvalidEmailOrPassword
    case RequiresLogin
    case AlamofireError(NSError)
    case AlamofireResponseError(ErrorType)
}

internal enum TransactionResult<DataType> {
    case Succeeded(DataType)
    case Failed(ApidocServerError)
}


internal typealias ApidocJsonHandler = (TransactionResult<AnyObject?>) -> Void

