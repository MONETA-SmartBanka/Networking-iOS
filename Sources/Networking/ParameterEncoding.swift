
import Foundation

public protocol ParametersEncoder {
    func encodeParameters(into request: URLRequest) throws -> URLRequest
    var logDescription: String? { get }
}

public final class JSONBodyParameters<Parameters: Encodable>: ParametersEncoder {
    let parameters: Parameters

    private let jsonEncoder: JSONEncoder

    public init(_ parameters: Parameters, jsonEncoder: JSONEncoder = .init()) {
        self.parameters = parameters
        self.jsonEncoder = jsonEncoder
    }

    public func encodeParameters(into request: URLRequest) throws -> URLRequest {
        var request = request
        let body = try jsonEncoder.encode(parameters)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        return request
    }

    public var logDescription: String? {
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        guard let jsonData = try? jsonEncoder.encode(parameters) else { return nil }
        return String(decoding: jsonData, as: UTF8.self)
    }
}

public final class URLQueryParameters: ParametersEncoder {
    let parameters: [String: CustomStringConvertible]

    public init(_ parameters: [String: CustomStringConvertible]) {
        self.parameters = parameters
    }

    public func encodeParameters(into request: URLRequest) throws -> URLRequest {
        guard !parameters.isEmpty else { return request }
        guard let url = request.url else {
            throw URLError(.badURL)
        }

        var request = request
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        
        components?.queryItems = parameters
            .map { URLQueryItem(name: $0.key, value: $0.value.description) }
        request.url = components?.url

        return request
    }

    public var logDescription: String? {
        parameters.map { "\($0.key) = \($0.value.description)" }.joined(separator: "\n")
    }
}
