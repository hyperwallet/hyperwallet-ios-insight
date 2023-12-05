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

struct Events: Codable {
    var events: [EventInsight]
}

struct EventInsight: Codable {
    var actor: Actor
    var channel: String
    var eventParams: [EventParams]

    enum CodingKeys: String, CodingKey {
        case actor
        case channel
        case eventParams = "event_params"
    }
}

struct Actor: Codable {
    var trackingVisitId: String
    var trackingVisitorId: String

    enum CodingKeys: String, CodingKey {
        case trackingVisitId = "tracking_visit_id"
        case trackingVisitorId = "tracking_visitor_id"
    }
}

struct EventParams: Codable {
    var component: String?
    var country: String?
    var currency: String?
    var deviceModel: String?
    var deviceName: String?
    var deviceType: String?
    var errorCode: String?
    var errorDescription: String?
    var errorFieldName: String?
    var errorMessage: String?
    var errorType: String?
    var eventType: String?
    var goal: String?
    var hyperwalletEnvironment: String?
    var hyperwalletIs: String?
    var link: String?
    var operatingSystem: String?
    var operatingSystemVersion: String?
    var orientation: String?
    var pageGroup: String?
    var pageName: String?
    var pageTechnologyFlag: String?
    var product: String?
    var profileType: String?
    var rosettaLanguage: String?
    var screenHeight: CGFloat?
    var screenWidth: CGFloat?
    var sdkVersion: String?
    var tenentName: String?
    var timestamp: Int64?
    var transferMethodType: String?

    enum CodingKeys: String, CodingKey {
        case component = "comp"
        case country = "hyperwallet_ea_country"
        case currency = "hyperwallet_ea_currency"
        case deviceModel = "dvmdl"
        case deviceName = "dvid"
        case deviceType = "dvis"
        case errorCode = "error_code"
        case errorDescription = "error_description"
        case errorFieldName = "erfd"
        case errorMessage = "error_message"
        case errorType = "error_type"
        case eventType = "e"
        case goal = "goal"
        case hyperwalletEnvironment = "hyperwallet_environment"
        case hyperwalletIs = "hyperwallet_is"
        case link = "link"
        case operatingSystem = "os"
        case operatingSystemVersion = "osv"
        case orientation = "device_orientation"
        case pageGroup = "pgrp"
        case pageName = "page"
        case pageTechnologyFlag = "pgtf"
        case product = "product"
        case profileType = "hyperwallet_profile_type"
        case rosettaLanguage = "rsta"
        case screenHeight = "sh"
        case screenWidth = "sw"
        case sdkVersion = "sdk_version"
        case tenentName = "tenent_name"
        case timestamp = "t"
        case transferMethodType = "hyperwallet_ea_type"
    }
}

struct EventConstants {
    static let channel = "mobile"
    static let click = "cl"
    static let error = "err"
    static let errorTypeForm = "FORM"
    static let hyperwalletComponent = "hwiosuisdk"
    static let impression = "im"
    static let operatingSystem = "iOS"
    static let product = "dropin"
    static let tenentName = "hyperwallet"
    static let swiftFramework = "Swift"
}
