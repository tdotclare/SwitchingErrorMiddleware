//
//  SwitchingErrorMiddleware.swift
//
//
//  Created by Teague Clare on 12/15/19.
//  Based on default ErrorMiddleware from Vapor 4.0.0-beta.3
//  Update to use req.storage - responseTypeHint
//
//  Switches on req.userInfo["errorType"] when set to html to return a Leaf template with the error.

import Vapor

/// Captures all errors and transforms them into an internal server error HTTP response.
public final class SwitchingErrorMiddleware: Middleware {
    /// Structure of `SwitchingErrorMiddleware` default response.
    internal struct ErrorResponse: Codable {
        /// Always `true` to indicate this is a non-typical JSON response.
        var error: Bool

        /// The reason for the error.
        var reason: String
    }

    /// Create a default `SwitchingErrorMiddleware`. Logs errors to a `Logger` based on `Environment`
    /// and converts `Error` to `Response` based on conformance to `AbortError` and `Debuggable`.
    ///
    /// - parameters:
    ///     - environment: The environment to respect when presenting errors.
    ///     - log: Log destination.
	public static func `default`(environment: Environment, returnType: HTTPMediaType = .json, template: String) -> SwitchingErrorMiddleware {
        return .init { req, error in
            // variables to determine
            let status: HTTPResponseStatus
            let reason: String
            let headers: HTTPHeaders
            let source: ErrorSource?

            // inspect the error type
            switch error {
            case let abort as AbortError:
                // this is an abort error, we should use its status, reason, and headers
                reason = abort.reason
                status = abort.status
                headers = abort.headers
                source = abort.source
            case let error as LocalizedError where !environment.isRelease:
                // if not release mode, and error is debuggable, provide debug
                // info directly to the developer
                reason = error.localizedDescription
                status = .internalServerError
                headers = [:]
                source = nil
            default:
                // not an abort error, and not debuggable or in dev mode
                // just deliver a generic 500 to avoid exposing any sensitive error info
                reason = "Something went wrong."
                status = .internalServerError
                headers = [:]
                source = nil
            }
            
            // Report with the values from the error
            if let source = source {
                req.logger.report(error: error, file: source.file, function: source.function, line: source.line)
            } else {
                req.logger.report(error: error)
            }
            
            // TC 12.20.19 - Below modified to switch on req.userInfo["errorType"] to return specific format when set
			// Options are html (using view template) or json
			// create a Response with appropriate status
            let response = Response(status: status, headers: headers)
			let responseType = req.storage[ResponseTypeHint.self] ?? returnType
            
			
			do {
				switch responseType {
                    case .html:
                            let errorResponse = ["code": String(status.code), "reason": reason]
                            _ = req.view.renderAsString(template, ["error" : errorResponse]).map { body in
                                response.body = .init(string: body)
                                response.headers.replaceOrAdd(name: .contentType, value: responseType.description)
                            }
                    case .json:
                            let errorResponse = ErrorResponse(error: true, reason: reason)
                            response.body = try .init(data: JSONEncoder().encode(errorResponse))
                            response.headers.replaceOrAdd(name: .contentType, value: responseType.description)
					default:
						throw "Invalid response type specified"
				}
			}
			catch {
				response.body = .init(string: "Oops: \(error)")
                response.headers.replaceOrAdd(name: .contentType, value: HTTPMediaType.plainText.description)
			}
			           
            return response
        }
    }

    /// Error-handling closure.
    private let closure: (Request, Error) -> (Response)

    /// Create a new `SwitchingErrorMiddleware`.
    ///
    /// - parameters:
    ///     - closure: Error-handling closure. Converts `Error` to `Response`.
    public init(_ closure: @escaping (Request, Error) -> (Response)) {
        self.closure = closure
    }

    /// See `Middleware`.
    public func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        return next.respond(to: request).flatMapErrorThrowing { error in
            return self.closure(request, error)
        }
    }
}


