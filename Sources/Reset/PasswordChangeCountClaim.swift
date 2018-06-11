import JWT

/// Identifies the number of times a user's password has been changed
/// - id: pcc
public struct PasswordChangeCountClaim: JWTClaim {
    /// The number of times the password has been changed
    public var value: Int

    /// See `Claim.init`
    public init(value: Int) {
        self.value = value
    }
}
