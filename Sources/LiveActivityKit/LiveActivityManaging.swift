import Foundation
import ActivityKit

@available(iOS 16.2, *)
protocol LiveActivityManaging {
    associatedtype Attributes: LiveActivityAttributes
    
    func startActivity(
        with attributes: Attributes,
        showing state: Activity<Attributes>.ContentState
    ) async -> Result<ActivityState, LiveActivityError>
    
    func updateActivity(
        with attributes: Attributes,
        to state: Activity<Attributes>.ContentState,
        expiringOn staleDate: Date?,
        notifyWith alertConfig: AlertConfiguration?
    ) async -> Result<ActivityState, LiveActivityError>
    
    func stopActivity(
        with attributes: Attributes,
        showing state: Activity<Attributes>.ContentState,
        expiringOn staleDate: Date?,
        dismissalPolicy: ActivityUIDismissalPolicy
    ) async -> Result<ActivityState, LiveActivityError>
}

@available(iOS 16.2, *)
extension LiveActivityManaging {
    func updateActivity(
        with attributes: Attributes,
        to state: Activity<Attributes>.ContentState,
        expiringOn staleDate: Date? = nil,
        notifyWith alertConfig: AlertConfiguration? = nil
    ) async -> Result<ActivityState, LiveActivityError> {
        await updateActivity(
            with: attributes,
            to: state,
            expiringOn: staleDate,
            notifyWith: alertConfig
        )
    }
    
    func stopActivity(
        with attributes: Attributes,
        showing state: Activity<Attributes>.ContentState,
        expiringOn staleDate: Date? = nil,
        dismissalPolicy: ActivityUIDismissalPolicy = .default
    ) async -> Result<ActivityState, LiveActivityError> {
        await stopActivity(
            with: attributes,
            showing: state,
            expiringOn: staleDate,
            dismissalPolicy: dismissalPolicy
        )
    }
}
