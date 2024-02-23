import Foundation
import ActivityKit

@available(iOS 16.1, *)
protocol LiveActivityManaging {
    associatedtype Attributes: LiveActivityAttributes
    
    func startActivity(with attributes: Attributes, showing state: Activity<Attributes>.ContentState) async -> Result<ActivityState, LiveActivityError>
}
