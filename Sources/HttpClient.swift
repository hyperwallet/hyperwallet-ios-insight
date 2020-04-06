//
// Copyright 2019 - Present Hyperwallet
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software
// and associated documentation files (the "Software"), to deal in the Software without restriction,
// including without limitation the rights to use, copy, modify, merge, publish, distribute,
// sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
// BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
// DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import Foundation

struct HttpClient {
    private let session: URLSession

    init() {
        self.session = HttpClient.createUrlSession()
    }

    func invalidateSession() {
        session.invalidateAndCancel()
    }

    func post(with url: String, httpBody: Data, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        if let url = URL(string: url) {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = httpBody
            let task = session.dataTask(with: request, completionHandler: completionHandler)
            task.resume()
        }
    }

    private static func createUrlSession() -> URLSession {
        let acceptLanguage: String = Locale.preferredLanguages.prefix(6).first ?? "en-US"
        let configuration = URLSessionConfiguration.ephemeral
        let applicationJson: String = "application/json"
        let contentType: String = "application/json; charset=UTF-8"
        let defaultTimeout: Double = 5.0

        configuration.timeoutIntervalForResource = defaultTimeout
        configuration.timeoutIntervalForRequest = defaultTimeout
        configuration.httpAdditionalHeaders = [
            "User-Agent": getUserAgent(),
            "Accept-Language": acceptLanguage,
            "Accept": applicationJson,
            "Content-Type": contentType
        ]
        return URLSession(configuration: configuration)
    }

    private static func getUserAgent() -> String {
        guard let info = Bundle(for: Insights.self).infoDictionary
            else { return "Insights/iOS/UnknownVersion" }

        let version = ProcessInfo.processInfo.operatingSystemVersion
        let osVersion = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
        let executable = info[kCFBundleExecutableKey as String] as? String ?? "Unknown"
        let sdkVersion = info["CFBundleShortVersionString"] as? String ?? "Unknown"
        let sdkBuild = info[kCFBundleVersionKey as String] as? String ?? "Unknown"
        let sdkBuildVersion = "\(sdkVersion).\(sdkBuild)"
        return "Insights/iOS/\(sdkBuildVersion); App: \(executable); iOS: \(osVersion)"
    }
}
