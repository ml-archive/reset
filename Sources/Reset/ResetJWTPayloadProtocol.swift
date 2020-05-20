import JWT
import Vapor

public protocol ResetJWTPayloadProtocol: JWTPayload {
    associatedtype User: Authenticatable

    static var expirationTimeInterval: TimeInterval { get }
    static var jwkIdentifier: JWKIdentifier { get }

    init(expirationDate: Date, user: User) throws
    func findUser(_ request: Request) -> EventLoopFuture<User>
}

extension ResetJWTPayloadProtocol {
    public static var expirationTimeInterval: TimeInterval { 3600 }
    public static var jwkIdentifier: JWKIdentifier { "rst" }
    public static var resetAuthenticator: some JWTAuthenticator { ResetAuthenticator<Self>() }

    public static func makeResetToken(
        for user: User,
        on request: Request,
        currentDate: Date = Date()
    ) throws -> String {
        try request.jwt.sign(
            Self(
                expirationDate: currentDate.addingTimeInterval(expirationTimeInterval),
                user: user
            ),
            kid: jwkIdentifier
        )
    }
}

struct ResetAuthenticator<R: ResetJWTPayloadProtocol>: JWTAuthenticator {
    func authenticate(
        jwt resetPayload: R,
        for request: Request
    ) -> EventLoopFuture<Void> {
        resetPayload.findUser(request).map(request.auth.login)
    }
}
