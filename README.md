# SwitchingErrorMiddleware
A Middleware for Vapor 4 that takes a returnType directive to branch error serving to json or html as required.

Example use:

In Vapor configure.swift (or equivalent for configuring Application):
```swift

   // Last middleware in main chain - Error handling
   // - return HTML errors by default, using Leaf template "error"
   a.middleware.use(SwitchingErrorMiddleware.default(environment: a.environment, returnType: .html, template: "error"))
   // - return JSON errors by default - if per route wants to throw html instead, use Leaf template "error"
   //a.middleware.use(SwitchingErrorMiddleware.default(environment: a.environment, returnType: .json, template: "error"))
```

In routes:
```swift
    // request closure hints ResponseType to HTML
    a.get("404html") { req -> EventLoopFuture<View> in
        req.storage.set(ResponseTypeHint.self, to: .html)
        throw Abort(.notFound)
    }
    
    // request closure hints ResponseType to JPEG (Middleware will fail because only HTML/JSON supported)
    a.get("404failure") { req -> EventLoopFuture<View> in
        req.storage.set(ResponseTypeHint.self, to: .jpeg)
        throw Abort(.notFound)
    }
    
    // request closure hints ResponseType to JSON
    a.get("404json") { req -> EventLoopFuture<View> in
        req.storage.set(ResponseTypeHint.self, to: .json)
        throw Abort(.notFound)
    }
```
