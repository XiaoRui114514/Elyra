// SPDX-License-Identifier: GPL-3.0-only
import Foundation

public enum DeviceBuildIdentification {
    public static func build(simulator: Bool, environmentBuild: String?, versionDescription: String, kernelBuild: String) -> String? {
        let token = "[0-9]{2}[A-Za-z][0-9]+[A-Za-z]?"
        func valid(_ value: String?) -> String? {
            guard let value, let range = value.range(of: "^" + token + "$", options: .regularExpression),
                  range.lowerBound == value.startIndex, range.upperBound == value.endIndex else { return nil }
            return value
        }
        if !simulator { return valid(kernelBuild) }
        // kern.osversion in Simulator describes the macOS host, not the iOS runtime.
        if let environment = valid(environmentBuild) { return environment }
        if let range = versionDescription.range(of: "(?<=Build )" + token + "(?=\\))", options: .regularExpression) {
            return String(versionDescription[range])
        }
        return nil
    }
}
