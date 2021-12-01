
import Foundation

public protocol ParametersEncoder {
    func encodeParameters(into request: URLRequest) throws -> URLRequest
    var logDescription: String? { get }
}

public protocol MultipartEncoder {
    func multipartEncode() throws -> Data
}

public final class JSONBodyParameters<Parameters: Encodable>: ParametersEncoder, MultipartEncoder  {
    let parameters: Parameters
    let multipartName: String?

    private let jsonEncoder: JSONEncoder

    public init(_ parameters: Parameters, jsonEncoder: JSONEncoder = .init(), multipartName: String? = nil) {
        self.parameters = parameters
        self.jsonEncoder = jsonEncoder
        self.multipartName = multipartName
    }

    public func encodeParameters(into request: URLRequest) throws -> URLRequest {
        var request = request
        let body = try jsonEncoder.encode(parameters)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        return request
    }

    public func multipartEncode() throws -> Data {
        guard let multipartName = multipartName
        else { throw ParameterEncodingError.multipartNameMissing }
        var data = Data()
        data.append(text: "Content-Disposition: form-data; name=\"\(multipartName)\"")
        data.appendNewLine()
        data.append(text: "Content-Type: application/json")
        data.appendNewLine()
        data.appendNewLine()
        data.append(try jsonEncoder.encode(parameters))
        return data
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

public final class ImageParameter: ParametersEncoder, MultipartEncoder {
    let image: Data
    let filename: String
    let multipartName: String?

    public init(image: Data, filename: String, multipartName: String? = nil) {
        self.image = image
        self.filename = filename
        self.multipartName = multipartName
    }

    public func encodeParameters(into request: URLRequest) throws -> URLRequest {
        var request = request
        request.addValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.httpBody = image
        return request
    }

    public func multipartEncode() throws -> Data {
        guard let multipartName = multipartName
        else { throw ParameterEncodingError.multipartNameMissing }
        var data = Data()
        data.append(text: "Content-Disposition: form-data; name=\"\(multipartName)\"; filename=\"\(filename)\"")
        data.appendNewLine()
        data.append(text: "Content-Type: image/jpeg")
        data.appendNewLine()
        data.appendNewLine()
        data.append(image)
        return data
    }

    public var logDescription: String? {
        "{IMAGE DATA - size: \(image.count)}"
    }
}

public final class MultipartBodyParams: ParametersEncoder {
    let multiparts: [MultipartEncoder]

    public init(multiparts: [MultipartEncoder]) {
        self.multiparts = multiparts
    }

    public func encodeParameters(into request: URLRequest) throws -> URLRequest {
        var request = request
        let boundary = UUID().uuidString
        let delimiter = "--\(boundary)\r\n"
        request.addValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        var data = Data()
        for multipart in multiparts {
            data.append(text: delimiter)
            data.append(try multipart.multipartEncode())
            data.appendNewLine()
        }
        request.httpBody = data

        return request
    }

    public var logDescription: String? { nil }
}

public enum ParameterEncodingError: Error {
    case multipartNameMissing
}

private extension Data {
    mutating func append(text: String?) {
        if let textData = text?.data(using: .utf8) {
            append(textData)
        }
    }

    mutating func appendNewLine() {
        append(text: "\r\n")
    }
}
