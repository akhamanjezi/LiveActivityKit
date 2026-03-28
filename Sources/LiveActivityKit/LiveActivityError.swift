import Foundation

public enum LiveActivityError: Error, Equatable, Sendable {
    case notEnabled
    case couldNotStart
    case activityNotFound
}
