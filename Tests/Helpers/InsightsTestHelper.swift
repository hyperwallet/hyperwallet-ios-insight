import Hippolyte
import XCTest
@testable import Insights

final class InsightsTestHelper {
    static let applicationJson = "application/json; charset=UTF-8"
    static let contentType = "Content-Type"
    static let restURL = "https://localhost/"

    static func buildPostRequest(baseUrl: String, _ response: StubResponse) -> StubRequest {
        return StubRequest.Builder()
            .stubRequest(withMethod: .POST, url: URL(string: baseUrl)!)
            .addHeader(withKey: contentType, value: applicationJson)
            .addResponse(response)
            .build()
    }
    
    static func okHTTPResponse(for responseFileName: String) -> StubResponse {
        let data = Data()
        return setUpMockedResponse(payload: data, httpCode: 200)
    }

    static func getDataFromJson(_ fileName: String) -> Data {
        let path = Bundle(for: self).path(forResource: fileName, ofType: "json")!
        return NSData(contentsOfFile: path)! as Data
    }

    static func setUpMockServer(request: StubRequest) {
        Hippolyte.shared.add(stubbedRequest: request)
        Hippolyte.shared.start()
    }

    static func setUpMockedResponse(payload: Data,
                                    error: NSError? = nil,
                                    httpCode: Int = 200,
                                    contentType: String = InsightsTestHelper.applicationJson) -> StubResponse {
        return responseBuilder(payload, httpCode, error)
            .addHeader(withKey: InsightsTestHelper.contentType, value: contentType)
            .build()
    }

    private static func responseBuilder(_ payload: Data,
                                        _ httpCode: Int,
                                        _ error: NSError? = nil) -> StubResponse.Builder {
        let stubResponseBuilder = StubResponse.Builder().defaultResponse()
        guard let error = error else {
            return stubResponseBuilder
                .stubResponse(withStatusCode: httpCode)
                .addBody(payload)
        }
        return stubResponseBuilder
            .stubResponse(withError: error)
    }

}
