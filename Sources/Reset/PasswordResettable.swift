import Authentication
import Fluent
import JWT
import Submissions
import Sugar
import Vapor

public protocol RequestCreatable {
    static func create(on request: Request) throws -> Future<Self>
}

extension RequestCreatable where Self: Decodable {
    public static func create(on req: Request) throws -> Future<Self> {
        return try req.content.decode(Self.self)
    }
}

extension RequestCreatable where Self: Submittable {
    public static func create(on req: Request) throws -> Future<Self> {
        return try req.content.decode(Self.Submission.self).createValid(on: req)
    }
}

public protocol HasPasswordChangeCount {
    var passwordChangeCount: Int { get }
}

public protocol HasRequestResetPasswordContext: LosslessStringConvertible {
    static func requestResetPassword() -> Self
}

public extension HasRequestResetPasswordContext where
    Self: RawRepresentable,
    Self.RawValue == String
{
    public init?(_ description: String) { self.init(rawValue: description) }
    public var description: String { return self.rawValue }
}

public enum ResetPasswordContext: String, HasRequestResetPasswordContext {
    case userRequestedToResetPassword

    public static func requestResetPassword() -> ResetPasswordContext {
        return .userRequestedToResetPassword
    }

    public init?(_ description: String) { self.init(rawValue: description) }
    public var description: String { return self.rawValue }
}

public protocol PasswordResettable:
    HasPassword,
    HasPasswordChangeCount,
    JWTAuthenticatable,
    Model
where
    Self.JWTPayload: HasPasswordChangeCount
{
    associatedtype RequestReset: RequestCreatable
    associatedtype ResetPassword: HasReadablePassword, RequestCreatable
    associatedtype Context: HasRequestResetPasswordContext

    static func find(
        by requestLink: RequestReset,
        on connection: DatabaseConnectable
    ) throws -> Future<Self?>

    func sendPasswordReset(
        url: String,
        token: String,
        expirationPeriod: TimeInterval,
        context: Context,
        on req: Request
    ) throws -> Future<Void>

    /// By incrementing this value on each password change and including it in the JWT payload,
    /// this value ensures that a password reset token can only be used once.
    var passwordChangeCount: Int { get set }

    static func signer(for context: Context, on container: Container) throws -> ExpireableJWTSigner
}

public extension PasswordResettable {
    static func signer(for context: Context, on container: Container) throws -> ExpireableJWTSigner {
        let defaultSigner: ExpireableJWTSigner = try container.make()
        return defaultSigner
    }
}

extension PasswordResettable where
    Self: PasswordAuthenticatable,
    Self.RequestReset: HasReadableUsername
{
    public static func find(
        by payload: RequestReset,
        on connection: DatabaseConnectable
    ) -> Future<Self?> {
        let username = payload[keyPath: RequestReset.readableUsernameKey]
        return query(on: connection).filter(Self.usernameKey == username).first()
    }
}

extension PasswordResettable where
    Self.JWTPayload: ModelPayloadType,
    Self == Self.JWTPayload.PayloadModel
{
    public func makePayload(
        expirationTime: Date,
        on container: Container
    ) -> Future<JWTPayload> {
        return Future.map(on: container) {
            try Self.JWTPayload.init(expirationTime: expirationTime, model: self)
        }
    }
}

public protocol ModelPayloadType: ExpireableSubjectPayload, HasPasswordChangeCount {
    associatedtype PayloadModel: Model
    init(expirationTime: Date, model: PayloadModel) throws
}

public struct ModelPayload<U: Model>:
    ModelPayloadType
where
    U: HasPasswordChangeCount,
    U.ID: LosslessStringConvertible
{
    public typealias PayloadModel = U

    public let exp: ExpirationClaim
    public let sub: SubjectClaim
    public let pcc: PasswordChangeCountClaim

    public init(
        expirationTime: Date,
        model: U
    ) throws {
        self.exp = ExpirationClaim(value: expirationTime)
        self.sub = try SubjectClaim(value: model.requireID().description)
        self.pcc = PasswordChangeCountClaim(value: model.passwordChangeCount)
    }

    public func verify(using signer: JWTSigner) throws {
        try exp.verifyNotExpired()
    }

    public var passwordChangeCount: Int {
        return pcc.value
    }
}
