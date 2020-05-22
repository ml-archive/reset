import JWT
import Vapor

public protocol KeychainConfig {
    associatedtype JWTPayload: KeychainPayload
    static var jwkIdentifier: JWKIdentifier { get }
    var expirationTimeInterval: TimeInterval { get }
}

extension KeychainConfig where JWTPayload.User: Authenticatable {
    public static var authenticator: some JWTAuthenticator { Authenticator<Self>() }
}

extension KeychainConfig {
    public func makeToken(
        for user: JWTPayload.User,
        on request: Request,
        currentDate: Date = Date()
    ) throws -> String {
        try request.jwt.sign(
            JWTPayload(
                expirationDate: currentDate.addingTimeInterval(expirationTimeInterval),
                user: user
            ),
            kid: Self.jwkIdentifier
        )
    }
}

struct Authenticator<T: KeychainConfig>: JWTAuthenticator where T.JWTPayload.User: Authenticatable {
    func authenticate(
        jwt resetPayload: T.JWTPayload,
        for request: Request
    ) -> EventLoopFuture<Void> {
        resetPayload.findUser(request: request).map(request.auth.login)
    }
}
