import Vapor

public protocol ForgotPasswordRequestProtocol {
    associatedtype Config: KeychainConfig

    static func sendToken(
        _ token: String,
        user: Config.JWTPayload.User,
        config: Config,
        request: Request
    ) -> EventLoopFuture<Void>

    init(request: Request) throws

    func findUser(request: Request) -> EventLoopFuture<Config.JWTPayload.User?>
}

public extension ForgotPasswordRequestProtocol {
    static func sendToken(request: Request) -> EventLoopFuture<Void> {
        do {
            return try Self(request: request)
                .findUser(request: request).flatMap { user -> EventLoopFuture<Void> in
                    guard let user = user else {
                        // when no user could be found, skip the steps below but pretend that the
                        // request was successful
                        return request.eventLoop.future()
                    }
                    let config = request.keychain.config(for: Config.self)
                    do {
                        let token = try config.makeToken(for: user, on: request)
                        return sendToken(token, user: user, config: config, request: request)
                    } catch {
                        return request.eventLoop.makeFailedFuture(error)
                    }
                }
        } catch {
            return request.eventLoop.makeFailedFuture(error)
        }
    }
}

public extension ForgotPasswordRequestProtocol where Self: Decodable {
    init(request: Request) throws {
        self = try request.content.decode(Self.self)
    }
}
