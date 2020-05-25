import Vapor

public protocol CreateRequest: ValidatableRequest {
    associatedtype Model

    func create(on request: Request) -> EventLoopFuture<Model>
}

public extension CreateRequest {
    static func create(on request: Request) -> EventLoopFuture<Model> {
        validated(on: request).flatMap { $0.create(on: request) }
    }
}
