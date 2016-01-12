//
//  Either.swift
//  ApidocSwiftGenerator
//
//  Created by Kyle Dorman on 1/5/16.
//
//

public enum Either<A, B> {
    case Left(A)
    case Right(B)
}