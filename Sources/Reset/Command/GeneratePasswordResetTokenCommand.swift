import Authentication
import Command
import Fluent
import Sugar

/// Generates password reset tokens for a user which can be used to reset their password.
public struct GeneratePasswordResetTokenCommand<U: PasswordResettable>: Command {
    /// See `Command`
    public let arguments: [CommandArgument] = [.argument(name: Keys.query)]

    /// See `CommandRunnable`
    public let options: [CommandOption] = []

    /// See `CommandRunnable`
    public let help = ["Generates a password reset token for a user with a given id."]

    private let makeFilter: (String) -> FilterOperator<U.Database, U>
    private let databaseIdentifier: DatabaseIdentifier<U.Database>
    private let context: U.Context

    /// Creates a new password reset token command with a custom lookup strategy.
    ///
    /// Example to enable search by email:
    /// ```
    /// GeneratePasswordResetTokenCommand(databaseIdentifier: .mysql) { query in
    ///     try \User.email == $0
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - databaseIdentifier: identifier of database from where to load the user.
    ///   - makeFilter: used to create the filter from the query.
    ///   - context: The Reset context to use when generating the token.
    public init(
        databaseIdentifier: DatabaseIdentifier<U.Database>,
        makeFilter: @escaping (String) -> FilterOperator<U.Database, U>,
        context: U.Context = U.Context.requestResetPassword()
    ) {
        self.databaseIdentifier = databaseIdentifier
        self.makeFilter = makeFilter
        self.context = context
    }

    /// See `CommandRunnable`
    public func run(using context: CommandContext) throws -> Future<Void> {
        let container = context.container
        let query = try context.argument(Keys.query)

        return container.withPooledConnection(to: databaseIdentifier) { connection in
            U
                .query(on: connection)
                .filter(self.makeFilter(query))
                .first()
                .unwrap(or: ResetError.userNotFound)
                .flatMap(to: String.self) { user in
                    let signer = try U.signer(for: self.context, on: container)
                    return try user.signToken(using: signer, on: container)
                }
                .map {
                    context.console.print("Password Reset Token: \($0)")
                }
        }
    }
}

public extension GeneratePasswordResetTokenCommand where U.ID: LosslessStringConvertible {
    /// Creates a new password reset token command that looks up users by database identifier.
    ///
    /// - Parameters:
    ///   - databaseIdentifier: identifier of database from where to load the user.
    ///   - context: The Reset context to use when generating the token.
    public init(
        databaseIdentifier: DatabaseIdentifier<U.Database>,
        context: U.Context = U.Context.requestResetPassword()
    ) {
        self.databaseIdentifier = databaseIdentifier
        self.makeFilter = { query -> FilterOperator<U.Database, U> in
            U.idKey == U.ID(query)
        }
        self.context = context
    }
}

private enum Keys {
    static let query = "query"
}
