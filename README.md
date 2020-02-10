# Reset 🏳
[![Swift Version](https://img.shields.io/badge/Swift-4.2-brightgreen.svg)](http://swift.org)
[![Vapor Version](https://img.shields.io/badge/Vapor-3-30B6FC.svg)](http://vapor.codes)
[![Circle CI](https://circleci.com/gh/nodes-vapor/reset/tree/master.svg?style=shield)](https://circleci.com/gh/nodes-vapor/reset)
[![codebeat badge](https://codebeat.co/badges/06ad8513-8a2d-4e68-acd7-16c2953f9326)](https://codebeat.co/projects/github-com-nodes-vapor-reset-master)
[![codecov](https://codecov.io/gh/nodes-vapor/reset/branch/master/graph/badge.svg)](https://codecov.io/gh/nodes-vapor/reset)
[![Readme Score](http://readme-score-api.herokuapp.com/score.svg?url=https://github.com/nodes-vapor/reset)](http://clayallsopp.github.io/readme-score?url=https://github.com/nodes-vapor/reset)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/nodes-vapor/reset/master/LICENSE)

This package makes it easy to handle flows that involves resetting a password. It's up for the consumer to decide how to distribute the token that allows one to reset the password.

## 📦 Installation

Add `Reset` to the package dependencies (in your `Package.swift` file):
```swift
dependencies: [
    ...,
    .package(url: "https://github.com/nodes-vapor/reset.git", from: "1.0.0")
]
```

as well as to your target (e.g. "App"):

```swift
targets: [
    ...
    .target(
        name: "App",
        dependencies: [... "Reset" ...]
    ),
    ...
]
```

Next, copy/paste the `Resources/Views/Reset` folder into your project in order to be able to use the provided Leaf files. These files can be changed as explained in the [Specifying the responses](#specifying-the-responses) section, however it's recommended to copy this folder to your project anyway. This makes it easier for you to keep track of updates and your project will work if you decide later on to not use your own customized leaf files.

## Getting started 🚀

First make sure that you've imported Reset everywhere it's needed:

```swift
import Reset
```

### Adding the Provider

Reset comes with a light-weight provider that we'll need to register in the `configure` function in our `configure.swift` file:

```swift
try services.register(ResetProvider<User>(config: ResetConfig(
        name: AppConfig.app.name,
        baseURL: AppConfig.app.url,
        signer: ExpireableJWTSigner(
            expirationPeriod: 3600, // 1 hour
            signer: .hs256(
                key: env(EnvironmentKey.Reset.signerKey, "secret-reset"
            ).convertToData())
        )
    ))
)
```

Please see [Making a `PasswordResettable` model](#making-a-passwordresettable-model) for more information on confirming a type to `PasswordResettable`.

### Adding the Reset routes

Make sure to add the relevant Reset routes, e.g. in your configure.swift or routes.swift:

```swift
services.register(Router.self) { container -> EngineRouter in
    let router = EngineRouter.default()
    try router.useResetRoutes(User.self, on: container)
    return router
}
```

### Adding the Leaf tag

This package comes with a small Leaf tag that is used to pass Reset-related information such as project name and project url to Leaf. To add it to your project, please do the following:

```swift
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
    services.register { _ -> LeafTagConfig in
        var tags = LeafTagConfig.default()
        tags.useResetLeafTags()
        return tags
    }
}
```

## Making a `PasswordResettable` model

There's a couple of things that needs to be in place for conforming your model to `PasswordResettable`. The following example is based on having a `User` model which you would like to add support for resetting a password.

### Request and reset structs

The first thing to define is the data that is needed in order to request a reset password flow and the data for actually resetting the password. It could look like this:

```swift
extension User: PasswordResettable {
    // ...
    
    public struct RequestReset: RequestCreatable, Decodable, HasReadableUsername {
        static let readableUsernameKey = \RequestReset.username
        public let username: String
    }

    public struct ResetPassword: RequestCreatable, Decodable, HasReadablePassword {
        static let readablePasswordKey = \ResetPassword.password
        public let password: String
    }

    // ..
}
```

Basically the username (this could also be the email) is needed to request a reset flow and a new password is needed to submit the password change.

> Note how that `RequestReset` conforms to `HasReadableUsername`. This enables Reset to implement the `find` method for looking up the user automatically.

### Sending the reset-password url

Once the user has requested to reset their password, the `sendPasswordReset` function will be called. The implementation could send the url by email or just include the token in a text message. It's up to the implementer to decide how to distribute this.

Here's an example using the [Mailgun](https://github.com/twof/VaporMailgunService) package to send out an email with the reset password url:

```swift
extension User: PasswordResettable {
    // ...

    public func sendPasswordReset(
        url: String,
        token: String,
        expirationPeriod: TimeInterval,
        context: ResetPasswordContext,
        on req: Request
    ) throws -> Future<Void> {
        let mailgun = try req.make(Mailgun.self)
        let expire = Int(expirationPeriod / 60) // convert to minutes

        return try req
            .make(LeafRenderer.self)
            .render(ViewPath.Reset.resetPasswordEmail, ["url": url, "expire": expire])
            .map(to: String.self) { view in
                String(bytes: view.data, encoding: .utf8) ?? ""
            }
            .map(to: Mailgun.Message.self) { html in
                Mailgun.Message(
                    from: "donotreply@reset.com",
                    to: self.email,
                    subject: "Reset password",
                    text: "Please turn on html to view this email.",
                    html: html
                )
            }
            .flatMap(to: Response.self) { message in
                try mailgun.send(message, on: req)
            }
            .transform(to: ())
    }

    // ..
}
```

### Handling multiple reset flows

There might be cases where you would want to have multiple signers for multiple different reset password flows. One example could be to handle the regular reset password flow as well as automatically resetting a password when a user gets created. By implementing the `signer` function, you're able to handle this:

```swift
extension User: PasswordResettable {
    // ...

    public enum MyResetPasswordContext: HasRequestResetPasswordContext {
        case userRequestedToResetPassword
        case newUserWithoutPassword

        public static func requestResetPassword() -> MyResetPasswordContext {
            return .userRequestedToResetPassword
        }
    }

    public func signer(
        for context: MyResetPasswordContext,
        on container: Container
    ) throws -> ExpireableJWTSigner {
        let resetConfig: ResetConfig<User> = try container.make() // The default signer
        let myConfig: MyConfig = try container.make() // Some project specific config that holds the extra signer

        switch context {
        case .userRequestedToResetPassword: return resetConfig.signer
        case .newUserWithoutPassword: return myConfig.newUserSetPasswordSigner
        }
    }

    // ..
}
```

> Please note that you need to implement your own `Context` if you want to handle multiple signers.

## Specifying the responses

All endpoints and responses that Reset uses can be overwritten. Reset provides responses for the following cases:

- Form for requesting a reset password flow
- Response for letting the user know that the reset password url has been sent
- Form for resetting the password
- Response for letting the user know that the password has been reset

Here's a small example where the request to reset password should only be exposed through the API:

```swift

let customResponse = ResetResponses(
    resetPasswordRequestForm: { req in
        return try HTTPResponse(status: .notFound).encode(for: req)
    },
    resetPasswordUserNotified: { req in
        return try HTTPResponse(status: .noContent).encode(for: req)
    },
    resetPasswordForm: { req, user in
        return try req
            .make(LeafRenderer.self)
            .render("MyPathForShowingResetForm")
            .encode(for: req)
    },
    resetPasswordSuccess: { req, user in
        return try req
            .make(LeafRenderer.self)
            .render("MyPathForShowingResetPasswordSuccess")
            .encode(for: req)
    }
)

```

This instance can then be used when registering the provider as explained in [Adding the Provider](#adding-the-provider).

Alternatively, instead of passing in `ResetResponses` in the `ResetConfig`, one could pass in their own implementation of `ResetControllerType` for full customizability.

## 🏆 Credits

This package is developed and maintained by the Vapor team at [Nodes](https://www.nodesagency.com).


## 📄 License

This package is open-sourced software licensed under the [MIT license](http://opensource.org/licenses/MIT)
