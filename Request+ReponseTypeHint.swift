//
//  Request+HeaderFlags.swift
//  App
//
//  Created by Teague Clare on 12/19/19.
//
//  Implements a hinting mechanism on Request to allow handlers to hint or branch on response hinting

import Vapor

public struct ResponseTypeHint: StorageKey {
	public typealias Value = HTTPMediaType
}
