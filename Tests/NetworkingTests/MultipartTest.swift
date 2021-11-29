import XCTest
@testable import Networking

final class MultipartTests: XCTestCase {
    let baseURL = URL(string: "http://test.com")!

    lazy var session = SessionService(
        baseURL: self.baseURL,
        dataProvider: MockSession.testSession(baseURL: self.baseURL),
        validation: HTTPResponseValidator(),
        decoder: JSONResponseDecoder()
    )

    func testMultipartError() throws {
        let publisher = session.publisher(for: MultipartRequest())
        let error = try expectError(publisher)

        XCTAssertEqual((error as? ParameterEncodingError), .multipartNameMissing)
    }

    func testMultipart() throws {
        struct JSON: Encodable {
            let test: String
        }
        let imageData = "This is image".data(using: .utf8)!
        let json = JSONBodyParameters(JSON(test: "test"), multipartName: "kdoví")
        let image = ImageParameter(image: imageData, filename: "test.png", multipartName: "test")
        let parameters = MultipartBodyParams(multiparts: [json, image])
        let request = try parameters.encodeParameters(into: URLRequest(url: baseURL))
        print(request.httpBody?.base64EncodedString())
    }
}

struct MultipartRequest: Request {
    typealias Response = EmptyResponse

    let path: String = "/test"
    let method: HTTPMethod = .post
    let parameters: ParametersEncoder?

    init() {
        struct JSON: Encodable {
            let test: String
        }
        let imageData = Data(base64Encoded: "VGhpcyBpcyBpbWFnZQ==")!
        let json = JSONBodyParameters(JSON(test: "test"))
        let image = ImageParameter(image: imageData, filename: "test.png", multipartName: "test")
        parameters = MultipartBodyParams(multiparts: [json, image])
    }
}
