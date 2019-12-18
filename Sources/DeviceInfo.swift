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

struct DeviceInfo {
    let deviceName: String
    let iosVersion: String

    lazy var deviceModel: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let deviceModel = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else {
                return identifier
            }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return deviceModel
    }()

    var deviceScreenHeight: CGFloat { return UIScreen.main.bounds.height }
    var deviceScreenWidth: CGFloat { return UIScreen.main.bounds.width }
    var deviceType: String { return UIDevice.current.userInterfaceIdiom.description }
    var orientation: String { return UIDevice.current.orientation.description }
    var languageCode: String { return Locale.preferredLanguages[0] }

    static var shared = DeviceInfo()

    private init() {
        deviceName = UIDevice.current.name
        iosVersion = UIDevice.current.systemVersion
    }
}

extension UIUserInterfaceIdiom {
    var description: String {
        switch self {
        case .phone:
            return "Mobile Phone"
        case .pad:
            return "Tablet"
        case .tv:
            return "TV"
        case .carPlay:
            return "CarPlay"
        default:
            return "Unknown"
        }
    }
}

extension UIDeviceOrientation {
    var description: String {
        switch self {
        case .portrait:
            return "portrait"
        case .portraitUpsideDown:
            return "portraitUpsideDown"
        case .landscapeLeft:
            return "landscapeLeft"
        case .landscapeRight:
            return "landscapeRight"
        case .faceUp:
            return "faceUp"
        case .faceDown:
            return "faceDown"
        default:
            return "unknown"
        }
    }
}
