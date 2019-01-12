import Leaf
import Sugar
import Vapor

public struct ResetResponses<U: JWTAuthenticatable> {
    private enum ViewPaths: String {
        case resetPasswordRequestForm = "Reset/Password/reset-password-request-form"
        case resetPasswordUserNotified = "Reset/Password/reset-password-request-success"
        case resetPasswordForm = "Reset/Password/reset-password-form"
        case resetPasswordSuccess = "Reset/Password/reset-password-success"
    }

    public let resetPasswordRequestForm: (Request) throws -> Future<Response>
    public let resetPasswordUserNotified: (Request) throws -> Future<Response>
    public let resetPasswordForm: (Request, U) throws -> Future<Response>
    public let resetPasswordSuccess: (Request, U) throws -> Future<Response>

    public init(
        resetPasswordRequestForm: @escaping (Request) throws -> Future<Response>,
        resetPasswordUserNotified: @escaping (Request) throws -> Future<Response>,
        resetPasswordForm: @escaping (Request, U) throws -> Future<Response>,
        resetPasswordSuccess: @escaping (Request, U) throws -> Future<Response>
    ) {
        self.resetPasswordRequestForm = resetPasswordRequestForm
        self.resetPasswordUserNotified = resetPasswordUserNotified
        self.resetPasswordForm = resetPasswordForm
        self.resetPasswordSuccess = resetPasswordSuccess
    }

    public static var `default`: ResetResponses {
        return .init(
            resetPasswordRequestForm: { req in
                return try req
                    .view()
                    .render(ViewPaths.resetPasswordRequestForm.rawValue)
                    .encode(for: req)
            },
            resetPasswordUserNotified: { req in
                guard
                    req.http.accept.comparePreference(for: .html, to: .json) == .orderedAscending
                else {
                    return try HTTPResponse(status: .ok).encode(for: req)
                }

                return try req
                    .view()
                    .render(ViewPaths.resetPasswordUserNotified.rawValue)
                    .encode(for: req)
            },
            resetPasswordForm: { req, user in
                return try req
                    .make(LeafRenderer.self)
                    .render(ViewPaths.resetPasswordForm.rawValue)
                    .encode(for: req)
            },
            resetPasswordSuccess: { req, user in
                guard
                    req.http.accept.comparePreference(for: .html, to: .json) == .orderedAscending
                else {
                    return try HTTPResponse(status: .ok).encode(for: req)
                }

                return try req
                    .view()
                    .render(ViewPaths.resetPasswordSuccess.rawValue)
                    .encode(for: req)
            }
        )
    }
}
