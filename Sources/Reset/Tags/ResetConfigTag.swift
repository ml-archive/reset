import Async
import Leaf
import TemplateKit

public final class ResetConfigTag: TagRenderer {
    public func render(tag: TagContext) throws -> Future<TemplateData> {
        try tag.requireParameterCount(1)
        let config = try tag.container.make(ResetConfigTagData.self)
        return Future.map(on: tag) { try config.viewData(for: tag.parameters[0], tag: tag) }
    }

    public init() {}
}

public final class ResetConfigTagData: Service {
    enum Keys: String {
        case name
        case baseURL
    }

    public let name: String
    public let baseURL: String

    init(name: String, baseURL: String) { 
        self.name = name
        self.baseURL = baseURL
    }

    func viewData(for data: TemplateData, tag: TagContext) throws -> TemplateData {
        guard let key = data.string else {
            throw tag.error(reason: "Wrong type given (expected a string): \(type(of: data))")
        }

        guard let parsedKey = Keys(rawValue: key) else {
            throw tag.error(reason: "Wrong argument given: \(key)")
        }

        switch parsedKey {
        case .name:
            return .string(name)
        case .baseURL:
            return .string(baseURL)
        }
    }
}
