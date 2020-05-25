import Vapor

public protocol UpdateRequest: ValidatableRequest {
    associatedtype Model

    func update(_ model: Model, on request: Request) -> EventLoopFuture<Model>

    static func validations(for model: Model, on request: Request) -> EventLoopFuture<Validations>
}

extension UpdateRequest {
    static func validations(for model: Model, on request: Request) -> EventLoopFuture<Validations> {
        validations(on: request)
    }
}

public extension UpdateRequest {
    static func update(_ model: Model, on request: Request) -> EventLoopFuture<Model> {
        validated(on: request).flatMap { $0.update(model, on: request) }
    }
}

public extension UpdateRequest where Model: Authenticatable {
    static func update(on request: Request) -> EventLoopFuture<Model> {
        do {
            return update(try request.auth.require(), on: request)
        } catch {
            return request.eventLoop.makeFailedFuture(error)
        }
    }
}
