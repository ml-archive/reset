import Vapor

public protocol ResetRequestProtocol {
    associatedtype User

    init(request: Request) throws

    static var hashedPasswordKey: ReferenceWritableKeyPath<User, String> { get }

    var password: String { get }
}

public extension ResetRequestProtocol {
    static func updatePassword(for user: User, on request: Request) -> EventLoopFuture<User> {
        do {
            return request
                .password
                .async
                .hash(try Self(request: request).password)
                .map {
                    user[keyPath: Self.hashedPasswordKey] = $0
                    return user
                }
        } catch {
            return request.eventLoop.makeFailedFuture(error)
        }
    }
}

public extension ResetRequestProtocol where User: Authenticatable {
    static func updatePassword(on request: Request) -> EventLoopFuture<User> {
        do {
            return updatePassword(for: try request.auth.require(), on: request)
        } catch {
            return request.eventLoop.makeFailedFuture(error)
        }
    }
}

public extension ResetRequestProtocol where Self: Decodable {
    init(request: Request) throws {
        self = try request.content.decode(Self.self)
    }
}
