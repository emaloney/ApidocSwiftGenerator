//
//  URLLoader.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/4/16.
//
//

import Foundation
import Alamofire
import CleanroomLogger

public class ApidocURLLoader: ApidocLoader {
    private static let registrationURL: NSURL = NSURL(string: "http://api.apidoc.me/users/authenticate")!

    public let url: NSURL
    public let token: String?
    public let email: String?
    public let password: String?
    public var userGuid: NSUUID? = nil

    private var headers: [String : String] {
        var h = [String : String]()

        if let token = token {
            h["Authorization"] = "Basic \(token.encodedForHttp!)"
        } else if let password = password, let email = email {
            let ep = (email + ":" + password).encodedForHttp
            h["Authorization"] = "Basic \(ep)"
        }

        if let userGuid = userGuid {
            h["X-User-Guid"] = userGuid.UUIDString.encodedForHttp
        }
        return h
    }

    public init(url: NSURL, token: String? = nil, email: String? = nil, password: String? = nil) {
        self.url = url
        self.token = token
        self.email = email
        self.password = password
    }

    public func load() -> NSDictionary? {
        return nil
    }

    public func load(handler: Apidoc.ApidocJsonHandler) {
        guard let _ = email, _ = password else {
            loadApidocJSON { result in
                switch result {
                case .Failed(let error):
                    handler(.Failed(error))
                    return
                case .Succeeded(let data):
                    handler(.Succeeded(data))
                    return
                }
            }
            return
        }

        registerThenLoad { result in
            switch result {
            case .Failed(let error):
                handler(.Failed(error))
                return
            case .Succeeded(let data):
                handler(.Succeeded(data))
                return
            }
        }
    }

    private func registerThenLoad(handler: Apidoc.ApidocJsonHandler) {
        self.register { [weak self] result in
            switch result {
            case .Failed(let error):
                handler(.Failed(error))
                return
            case .Succeeded:
                self?.loadApidocJSON(handler)
                return
            }
        }
    }

    private func loadApidocJSON(handler: Apidoc.ApidocJsonHandler) {
        Alamofire.request(.GET, url.URLString, headers: headers)
            .response { request, response, data, error in

                guard error == nil else {
                    handler(.Failed(.AlamofireError(error!)))
                    return
                }

                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions(rawValue: 0))
                    handler(.Succeeded(json))
                } catch {
                    let json = String(data: data!, encoding: NSUTF8StringEncoding)
                    Log.error?.message(json ?? "Unable to parse data")
                    handler(.Failed(.RequiresLogin))
                }
        }

    }

    private func register(handler: Apidoc.ApidocJsonHandler) {
        guard let email = email, password = password else {
            handler(.Failed(ApidocServerError.MissingEmailOrPassword))
            return
        }
        let parameters = [
            "email" : email,
            "password" : password
        ]

        Alamofire.request(.POST, ApidocURLLoader.registrationURL, parameters: parameters, encoding: .JSON, headers: headers)
            .responseJSON { [weak self] response in
                switch response.result {
                case .Failure(let error):
                    handler(.Failed(.AlamofireResponseError(error)))
                case .Success(let json):
                    guard let payload = json as? NSDictionary else {
                        handler(.Failed(.InvalidToken))
                        return
                    }
                    guard let guid = payload["guid"] as? String else {
                        handler(.Failed(.InvalidToken))
                        return
                    }
                    self?.userGuid = NSUUID(UUIDString: guid)!
                    handler(.Succeeded(nil))
                    return
                }
        }
    }
}

public enum ApidocServerError: ErrorType {
    case InvalidToken
    case MissingEmailOrPassword
    case InvalidEmailOrPassword
    case RequiresLogin
    case AlamofireError(NSError)
    case AlamofireResponseError(ErrorType)
}

public enum TransactionResult<DataType> {
    case Succeeded(DataType)
    case Failed(ApidocServerError)
}

extension String {
    private var encodedForHttp: String? {
        guard let data = self.dataUsingEncoding(NSUTF8StringEncoding) else {
            return nil
        }
        return data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
    }
}

