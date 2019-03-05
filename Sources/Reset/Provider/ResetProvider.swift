import Authentication
import Fluent
import JWT
import Leaf
import Sugar
import Vapor

public final class ResetProvider<U: JWTAuthenticatable & PasswordResettable> {
    private let configFactory: (Container) throws -> ResetConfig<U>

    public init(configFactory: @escaping (Container) throws -> ResetConfig<U>) {
        self.configFactory = configFactory
    }
}

// MARK: - Provider

extension ResetProvider: Provider {
    public func register(_ services: inout Services) throws {
        services.register(factory: configFactory)

        services.register { container -> ResetConfigTagData in
            let config: ResetConfig<U> = try container.make()
            return ResetConfigTagData(name: config.name, baseURL: config.baseURL)
        }
    }

    public func didBoot(_ container: Container) throws -> Future<Void> {
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
            post(
                resetPasswordPath, String.parameter,
                use: controller.resetPassword
            )
        }
    }
}

// MARK: Leaf tags

public extension LeafTagConfig {
    public mutating func useResetLeafTags() {
        use(ResetConfigTag(), as: "reset:config")
    }
}
