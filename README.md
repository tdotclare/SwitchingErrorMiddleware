# SwitchingErrorMiddleware
A Middleware for Vapor 4 that takes a returnType directive to branch error serving to json or html as required. Uses 

Example use:

In Vapor configure.swift (or equivalent for configuring Application):
```swift

   // Last middleware in main chain - Error handling
   // - return HTML errors by default, using Leaf template "error"
   a.middleware.use(SwitchingErrorMiddleware.default(environment: a.environment, returnType: .html, template: "error"))
   // - return JSON errors by default - if per route wants to throw html instead, use Leaf template "error"
   a.middleware.use(SwitchingErrorMiddleware.default(environment: a.environment, returnType: .json, template: "error"))
```
