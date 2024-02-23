import Foundation

public enum LiveActivityError: Error {
    case notEnabled
    case alreadyInProgress
    case couldNotStart
    case notActive
}
