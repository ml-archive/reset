import Vapor

public enum ResetError: Error {
    case tokenAlreadyUsed
    case userNotFound
}

// MARK: - AbortError
extension ResetError: AbortError {
    public var status: HTTPResponseStatus {
        switch self {
        case .tokenAlreadyUsed  : return .forbidden
        case .userNotFound      : return .notFound
        }
    }

    public var reason: String {
        switch self {
        case .tokenAlreadyUsed  : return "A password reset token can only be used once."
        case .userNotFound      : return "Could not find user."
        }
    }
}

// MARK: - Debuggable
extension ResetError: Debuggable {
    public var identifier: String {
        switch self {
        case .tokenAlreadyUsed  : return "tokenAlreadyUsed"
        case .userNotFound      : return "userNotFound"
        }
    }
}
