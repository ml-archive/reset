import Authentication
import Fluent
import JWT
import Leaf
import Sugar
import Vapor

public final class ResetProvider<U: JWTAuthenticatable & PasswordResettable> {
    public let config: ResetConfig<U>

    public init(config: ResetConfig<U>) {
        self.config = config
    }
}

// MARK: - Provider

extension ResetProvider: Provider {
    public func register(_ services: inout Services) throws {
        try services.register(MutableLeafTagConfigProvider())
        services.register(config)
        services.register(ResetConfigTagData(name: config.name, baseURL: config.baseURL))
    }

    public func didBoot(_ container: Container) throws -> Future<Void> {
        let tags: MutableLeafTagConfig = try container.make()
        tags.use(ResetConfigTag(), as: "reset:config")

        return .done(on: container)
    }
}

// MARK: - Commands

extension ResetProvider where U.Database: QuerySupporting, U.ID: LosslessStringConvertible {
    public static func commands(
        databaseIdentifier: DatabaseIdentifier<U.Database>
    ) -> [String: Command] {
        return [
            "reset:generate-token": GeneratePasswordResetTokenCommand<U>(
                databaseIdentifier: databaseIdentifier
            )
        ]
    }
}

// MARK: - Routes

public extension Router {
    public func useResetRoutes<U: JWTAuthenticatable & PasswordResettable>(
        _ type: U.Type,
        on container: Container
    ) throws {
        let config: ResetConfig<U> = try container.make()
        let endpoints = config.endpoints
        let controller = config.controller

        if let renderResetPasswordRequestPath = endpoints.renderResetPasswordRequest {
            get(
                renderResetPasswordRequestPath,
                use: controller.renderResetPasswordRequestForm
            )
        }

        if let resetPasswordRequestPath = endpoints.resetPasswordRequest {
            post(resetPasswordRequestPath, use: controller.resetPasswordRequest)
        }

        if let renderResetPasswordPath = endpoints.renderResetPassword {
            get(
                renderResetPasswordPath, String.parameter,
                use: controller.renderResetPasswordForm
            )
        }

        if let resetPasswordPath = endpoints.resetPassword {
            post(resetPasswordPath, String.parameter, use: controller.resetPassword)
        }
    }
}
