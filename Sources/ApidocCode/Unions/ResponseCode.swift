//
//  ResponseCode.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/6/16.
//
//

import Foundation

public protocol ResponseCode {}

extension Int: ResponseCode {}

extension ResponseCodeOption: ResponseCode {}