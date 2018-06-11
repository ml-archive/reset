import Authentication
import Fluent
import JWT
import Sugar
import Vapor

public protocol HasPasswordChangeCount {
    var passwordChangeCount: Int { get }
}

public protocol PasswordResettable:
    HasPassword,
    HasPasswordChangeCount,
    JWTAuthenticatable,
    Model
where
    Self.Database: QuerySupporting,
    Self.JWTPayload: HasPasswordChangeCount
{
    associatedtype RequestLink: Decodable
    associatedtype ResetPassword: HasReadablePassword

    static func find(
        by requestLink: RequestLink,
        on connection: DatabaseConnectable
    ) throws -> Future<Self?>

    func sendPasswordReset(
        url: String,
        token: String,
        expirationPeriod: TimeInterval,
        on req: Request
    ) throws -> Future<Void>

    /// By incrementing this value on each password change and including it in the JWT payload,
    /// this value ensures that a password reset token can only be used once.
    var passwordChangeCount: Int { get set }
}

extension PasswordResettable where Self.ID: LosslessStringConvertible {
    public static func authenticate(
        using payload: JWTPayload,
        on connection: DatabaseConnectable
    ) throws -> Future<Self?> {
        guard let id = ID(payload.sub.value) else {
            throw Sugar.AuthenticationError.malformedPayload
        }

        return try find(id, on: connection)
    }
}

extension PasswordResettable where
    Self: PasswordAuthenticatable,
    Self.RequestLink: HasReadableUsername
{
    public static func find(
        by payload: RequestLink,
        on connection: DatabaseConnectable
    ) throws -> Future<Self?> {
        let username = payload[keyPath: RequestLink.readableUsernameKey]
        return try query(on: connection).filter(Self.usernameKey == username).first()
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
    var pcc: PasswordChangeCountClaim { get }
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

    public func verify() throws {
        try exp.verify()
    }

    public var passwordChangeCount: Int {
        return pcc.value
    }
}
