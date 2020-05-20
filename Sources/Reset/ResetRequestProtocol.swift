import Vapor

public protocol ResetRequestProtocol {
    associatedtype User

    var password: String { get }

    init(request: Request) throws

    static var hashedPasswordKey: ReferenceWritableKeyPath<User, String> { get }
}

public extension ResetRequestProtocol {
    static func updatePassword(for user: User, on request: Request) -> EventLoopFuture<Void> {
        do {
            return request
                .password
                .async
                .hash(try Self(request: request).password)
                .map { user[keyPath: Self.hashedPasswordKey] = $0 }
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
