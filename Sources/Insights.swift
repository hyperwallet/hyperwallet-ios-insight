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

import os.log

/// Describes requirements to track errors, clicks, and impression
public protocol InsightsProtocol {
    /// Instance method to track the client's clicks (taps)
    ///
    /// - Parameters:
    ///   - pageName: The Page or screen that is currently visible
    ///     This is a description of the page that the user is currently looking at. The value differs per page.
    ///     Example: transfer-method:add:select-transfer-method
    ///
    ///   - pageGroup: The group of the Page or screen that is currently visible
    ///     This is a description of the page that the user is currently looking at. The value differs per page.
    ///     Example: transfer-method
    ///
    ///   - link: The Link clicked by user in combination with event 'cl'.
    ///     Save, Next, Add, etc. This is the name of the button clicked.
    ///     Example: Add
    ///
    ///   - params: Dictionary contains client event parameters. The values differ per page.
    ///     Keys possible values example: country, currency, goal, profileType, transferMethodType.
    ///
    func trackClick(pageName: String, pageGroup: String, link: String, params: [String: String])

    /// Instance method to track the client's errors
    ///
    /// - Parameters:
    ///   - pageName: The Page or screen that is currently visible
    ///     This is a description of the page that the user is currently looking at. The value differs per page.
    ///     Example: transfer-method:add:select-transfer-method
    ///
    ///   - pageGroup: The group of the Page or screen that is currently visible
    ///     This is a description of the page that the user is currently looking at. The value differs per page.
    ///     Example: transfer-method
    ///
    ///   - errorInfo: The ErrorInfo structure is used to describe an occurred error
    ///
    func trackError(pageName: String, pageGroup: String, errorInfo: ErrorInfo)

    /// Instance method to track the client's impression
    ///
    /// - Parameters:
    ///   - pageName: The Page or screen that is currently visible
    ///     This is a description of the page that the user is currently looking at. The value differs per page.
    ///     Example: transfer-method:add:select-transfer-method
    ///
    ///   - pageGroup: The group of the Page or screen that is currently visible
    ///     This is a description of the page that the user is currently looking at. The value differs per page.
    ///     Example: transfer-method
    ///
    ///   - params: Dictionary contains client event parameters. The values differ per page.
    ///     Keys possible values example: country, currency, goal, profileType, transferMethodType.
    ///
    func trackImpression(pageName: String, pageGroup: String, params: [String: String])
}

/// Provides ability to client software to track errors, clicks, and impression
public final class Insights: InsightsProtocol {
    private let cacheThresholdDays = -7
    private let eventDispatchQueue = DispatchQueue(label: "insights_dispatch_queue",
                                                   qos: .background)
    private let maxBatchSize = 10

    private var apiUrl: String
    private var environment: String
    private var flushBackGroundDataTask = UIBackgroundTaskIdentifier.invalid
    private var programToken: String
    private var sdkVersion: String
    private var userToken: String
    private var visitId: String

    private let flushInProgressSemaphore = DispatchSemaphore(value: 1)

    private static var instance: Insights?

    /// A shared singleton property is an instance of Insights framework
    public static var shared: Insights? {
        instance
    }

    private lazy var httpClient = HttpClient()

    private init(environment: String, programToken: String, sdkVersion: String, apiUrl: String, userToken: String) {
        self.environment = environment
        self.programToken = programToken
        self.sdkVersion = sdkVersion
        self.apiUrl = apiUrl
        self.userToken = userToken
        visitId = UUID().uuidString
    }

    /// Clears Insights instance.
    public static func clearInstance() {
        if let httpClient = instance?.httpClient {
            httpClient.invalidateSession()
        }
        instance?.removeObserversForTrackingLifecycleEvents()
        instance = nil
    }

    /// Set up the shared instance of the Insights framework
    ///
    /// - Parameters:
    ///   - environment: Hyperwallet Environment where events occur.
    ///     One of: PROD, UAT, QAMASTER, QATRUNK, LOAD, BETA.
    ///
    ///   - programToken: Hyperwallet IS Program token. Template: 'prg-' + UUID.
    ///
    ///   - sdkVersion: The version of the Mobile UI SDK, Mobile Core SDK, Web UI SDK, Server UI SDK or API used.
    ///     The knowledge of the version is useful from a version tracking perspective.
    ///
    ///   - apiUrl: Lighthouse API platform endpoint.
    ///
    ///   - userToken: ID given to the unique visitor. Template: 'usr-' + UUID.
    ///
    public static func setup(environment: String,
                             programToken: String,
                             sdkVersion: String,
                             apiUrl: String,
                             userToken: String) {
        if instance == nil {
            instance = Insights(environment: environment,
                                programToken: programToken,
                                sdkVersion: sdkVersion,
                                apiUrl: apiUrl,
                                userToken: userToken)

            instance?.addObserversForTrackingLifecycleEvents()
        }
    }

    public func trackClick(pageName: String, pageGroup: String, link: String, params: [String: String]) {
        eventDispatchQueue.async { [weak self] in
            self?.trackEvent(eventType: EventConstants.click,
                             pageName: pageName,
                             pageGroup: pageGroup,
                             link: link,
                             eventParams: params)
        }
    }

    public func trackError(pageName: String, pageGroup: String, errorInfo: ErrorInfo) {
        eventDispatchQueue.async { [weak self] in
            self?.trackEvent(eventType: EventConstants.error,
                             pageName: pageName,
                             pageGroup: pageGroup,
                             errorInfo: errorInfo)
        }
    }

    public func trackImpression(pageName: String, pageGroup: String, params: [String: String]) {
        eventDispatchQueue.async { [weak self] in
            self?.trackEvent(eventType: EventConstants.impression,
                             pageName: pageName,
                             pageGroup: pageGroup,
                             eventParams: params)
        }
    }

    private func addObserversForTrackingLifecycleEvents() {
        let application = UIApplication.shared
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEnterBackground(_:)),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: application)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willBeTerminated(_:)),
                                               name: UIApplication.willTerminateNotification,
                                               object: application)
    }

    private func removeObserversForTrackingLifecycleEvents() {
        let application = UIApplication.shared
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.didEnterBackgroundNotification,
                                                  object: application)
        NotificationCenter.default.removeObserver(self,
                                                  name: UIApplication.willTerminateNotification,
                                                  object: application)
    }

    private func buildErrorEventParams(_ errorInfo: ErrorInfo?, _ eventParams: inout EventParams) {
        guard let errorInfo = errorInfo else {
            return
        }
        eventParams.errorCode = errorInfo.code
        eventParams.errorDescription = errorInfo.description
        eventParams.errorFieldName = errorInfo.fieldName
        eventParams.errorMessage = errorInfo.message
        eventParams.errorType = errorInfo.type
    }

    private func buildGenericEventParams(eventType: String,
                                         pageName: String,
                                         pageGroup: String,
                                         link: String?,
                                         _ eventParams: inout EventParams) {
        eventParams.eventType = eventType
        eventParams.pageName = pageName
        eventParams.pageGroup = pageGroup
        eventParams.link = link
        eventParams.component = EventConstants.hyperwalletComponent
        eventParams.hyperwalletEnvironment = environment
        eventParams.hyperwalletIs = programToken
        eventParams.operatingSystem = EventConstants.operatingSystem
        eventParams.pageTechnologyFlag = EventConstants.swiftFramework
        eventParams.tenentName = eventParams.tenentName ?? EventConstants.tenentName
        eventParams.component = eventParams.component ?? EventConstants.hyperwalletComponent
        eventParams.product = eventParams.product ?? EventConstants.product
        eventParams.sdkVersion = sdkVersion
        eventParams.timestamp = Date().epochMilliseconds()
    }

    private func buildDeviceInfoEventParams(_ eventParams: inout EventParams) {
        eventParams.deviceModel = DeviceInfo.shared.deviceModel
        eventParams.deviceName = DeviceInfo.shared.deviceName
        eventParams.deviceType = DeviceInfo.shared.deviceType
        eventParams.orientation = DeviceInfo.shared.orientation
        eventParams.screenHeight = DeviceInfo.shared.deviceScreenHeight
        eventParams.screenWidth = DeviceInfo.shared.deviceScreenWidth
        eventParams.operatingSystemVersion = DeviceInfo.shared.iosVersion
        eventParams.rosettaLanguage = DeviceInfo.shared.languageCode
    }

    private func buildClientEventParams(_ clientEventParams: [String: String]?, _ eventParams: inout EventParams) {
        guard let clientEventParams = clientEventParams,
            let jsonData = try? JSONSerialization.data(withJSONObject: clientEventParams),
            let decodedEventParams = try? JSONDecoder().decode(EventParams.self, from: jsonData) else {
                return
        }
        eventParams = decodedEventParams
    }

    private func enrichEvent(eventType: String,
                             pageName: String,
                             pageGroup: String,
                             link: String?,
                             eventParams clientEventParams: [String: String]?,
                             errorInfo: ErrorInfo?) -> EventInsight {
        let eventParams = enrichEventParams(eventType: eventType,
                                            pageName: pageName,
                                            pageGroup: pageGroup,
                                            link: link,
                                            clientEventParams: clientEventParams,
                                            errorInfo: errorInfo)
        let actor = Actor(trackingVisitId: visitId, trackingVisitorId: userToken)
        let eventInsight = EventInsight(actor: actor,
                                        channel: EventConstants.channel,
                                        eventParams: [eventParams])
        return eventInsight
    }

    private func enrichEventParams(eventType: String,
                                   pageName: String,
                                   pageGroup: String,
                                   link: String?,
                                   clientEventParams: [String: String]?,
                                   errorInfo: ErrorInfo?) -> EventParams {
        var eventParams = EventParams()
        buildClientEventParams(clientEventParams, &eventParams)
        buildGenericEventParams(eventType: eventType,
                                pageName: pageName,
                                pageGroup: pageGroup,
                                link: link,
                                &eventParams)
        buildErrorEventParams(errorInfo, &eventParams)
        buildDeviceInfoEventParams(&eventParams)

        return eventParams
    }

    private func trackEvent(eventType: String,
                            pageName: String,
                            pageGroup: String,
                            link: String? = nil,
                            eventParams: [String: String]? = nil,
                            errorInfo: ErrorInfo? = nil) {
        let eventInsight = enrichEvent(eventType: eventType,
                                       pageName: pageName,
                                       pageGroup: pageGroup,
                                       link: link,
                                       eventParams: eventParams,
                                       errorInfo: errorInfo)
        guard let jsonData = try? JSONEncoder().encode(eventInsight)
            else {
                print("error: Can't encode EventInsight instance")
                return
        }
        EventManager.shared.saveEvent(payload: jsonData)
        flushIfReachedMaxBatchSize()
    }

    private func flushIfReachedMaxBatchSize() {
        let eventsCount = EventManager.shared.getEventsCount()
        if maxBatchSize <= eventsCount {
            flushData()
        }
    }

    private func flushData() {
        guard flushInProgressSemaphore.wait(timeout: .now()) == .success else {
            return
        }
        let currentTime = Date().epochMilliseconds()
        let savedEvents = EventManager.shared.loadEvents(before: currentTime)
        guard !savedEvents.isEmpty else {
            flushInProgressSemaphore.signal()
            return
        }
        sendEvents(Events(events: savedEvents)) { [weak self] result in
            switch result {
            case .success(let response):
                if response {
                    EventManager.shared.deleteEvents(before: currentTime)
                } else {
                    self?.deleteStaleEvents()
                }

            case .failure(let error):
                os_log("%@", log: .default, type: .error, error.localizedDescription)
                self?.deleteStaleEvents()
            }
            self?.flushInProgressSemaphore.signal()
        }
    }

    private func sendEvents(_ events: Events, completion: @escaping (Result<Bool, Error>) -> Void) {
        var requestBody: Data
        do {
            requestBody = try JSONEncoder().encode(events)
        } catch {
            completion(.failure(error))
            return
        }
        httpClient.post(with: apiUrl, httpBody: requestBody) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let response = response as? HTTPURLResponse else {
                let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorBadServerResponse)
                completion(.failure(error))
                return
            }
            let result = (200...299).contains(response.statusCode)
            if result, let data = data {
                let parsedData = try? JSONSerialization.jsonObject(with: data, options: [])
                os_log("BatchId in response is: %@", String(describing: parsedData))
            }
            completion(.success(result))
        }
    }

    private func deleteStaleEvents() {
        let staleEpochMilliseconds = Date()
            .addingTimeInterval(TimeInterval(cacheThresholdDays * 24 * 3600))
            .epochMilliseconds()
        EventManager.shared.deleteEvents(before: staleEpochMilliseconds, isStale: true)
    }

    @objc
    private func didEnterBackground(_: NSNotification) {
        eventDispatchQueue.async {
            self.flushBackGroundDataTask = UIApplication.shared
                .beginBackgroundTask(withName: "FlushData") { [weak self] in
                    guard let strongSelf = self,
                        strongSelf.flushBackGroundDataTask != UIBackgroundTaskIdentifier.invalid else {
                            return
                    }
                    UIApplication.shared.endBackgroundTask(strongSelf.flushBackGroundDataTask)
                    strongSelf.flushBackGroundDataTask = UIBackgroundTaskIdentifier.invalid
                }
        }
        eventDispatchQueue.sync {
            flushData()
        }
    }

    @objc
    private func willBeTerminated(_: NSNotification) {
        eventDispatchQueue.sync {
            flushData()
            flushInProgressSemaphore.wait()
        }
    }
}

/// The ErrorInfo structure is used to describe an occurred error
public struct ErrorInfo {
    let type: String
    let message: String
    let fieldName: String
    let description: String
    let code: String

    /// The ErrorInfo structure public initializer
    ///
    /// - Parameters:
    ///   - type: The Type of error that occurred.
    ///     One of: API, FORM, CONNECTION, EXCEPTION
    ///
    ///   - message: The Field Name is especially interesting when there is a validation error/issue in combination
    ///     with error_type = FORM
    ///
    ///   - fieldName: The Field Name is especially interesting when there is a validation error/issue in combination
    ///     with error_type = FORM or when an API error occurs in relation to a field, error_type = API
    ///
    ///   - description: The Source of error that occurred. This allows to understand what caused the error.
    ///     This is a detailed description, such as a stack trace. This is especially important for
    ///     error_type = EXCEPTION.
    ///
    ///   - code: The Error Code is the type of error that occurred
    ///     If error type is FIELD, the value can be:
    ///     - empty
    ///     - length
    ///     - pattern
    ///
    ///     If error type is API, the error code from the API is used, example:
    ///     - CONSTRAINT_VIOLATIONS
    ///
    ///     If error type is NETWORK, the error code could be (not exhaustive):
    ///     - timeout
    ///     - unable to resolve hostname
    ///
    ///     In case of an EXCEPTION, return a system value
    public init(type: String, message: String, fieldName: String, description: String, code: String) {
        self.type = type
        self.message = message
        self.fieldName = fieldName
        self.description = description
        self.code = code
    }
}
