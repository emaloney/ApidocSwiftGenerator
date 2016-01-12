//
//  URLConstructor.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/4/16.
//
//

import Foundation

public struct URLConstructor {
    public static func create(organizationKey: String, applicationKey: String, version optionalVersion: String?) -> NSURL? {
        var version: String
        if (optionalVersion == nil) {
            version = "latest"
        } else {
            version = optionalVersion!
        }

        return NSURL(string: "http://api.apidoc.me/" + organizationKey + "/" + applicationKey + "/" + version)!
    }
}