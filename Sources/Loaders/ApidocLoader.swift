//
//  ApidocLoader.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/4/16.
//
//

import Foundation

internal protocol ApidocLoader {
    func load() -> NSDictionary?
}