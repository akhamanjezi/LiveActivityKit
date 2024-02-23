import Foundation

enum LiveActivityError: Error {
    case notEnabled
    case alreadyInProgress
    case couldNotStart
}
