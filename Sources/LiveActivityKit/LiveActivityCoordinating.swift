#if canImport(ActivityKit)
import Foundation
import ActivityKit

@available(iOS 16.2, *)
public protocol LiveActivityCoordinating {
    associatedtype Attributes: LiveActivityAttributes
    
    var currentActivities: [Activity<Attributes>] { get }
    
    func startActivity(
        with attributes: Attributes,
        showing state: Activity<Attributes>.ContentState
    ) -> Result<ActivityState, LiveActivityError>
    
    func updateActivity(
        with attributes: Attributes,
        to state: Activity<Attributes>.ContentState,
        expiringOn staleDate: Date?,
        notifyWith alertConfig: AlertConfiguration?
    ) async -> Result<ActivityState, LiveActivityError>
    
    func stopActivity(
        with attributes: Attributes,
        showing state: Activity<Attributes>.ContentState?,
        expiringOn staleDate: Date?,
        dismissalPolicy: ActivityUIDismissalPolicy
    ) async -> Result<ActivityState, LiveActivityError>
    
    func endAll(
        dismissalPolicy: ActivityUIDismissalPolicy
    )
}

@available(iOS 16.2, *)
public extension LiveActivityCoordinating {
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
        showing state: Activity<Attributes>.ContentState? = nil,
        expiringOn staleDate: Date? = nil,
        dismissalPolicy: ActivityUIDismissalPolicy = .immediate
    ) async -> Result<ActivityState, LiveActivityError> {
        await stopActivity(
            with: attributes,
            showing: state,
            expiringOn: staleDate,
            dismissalPolicy: dismissalPolicy
        )
    }
    
    func endAll(
        dismissalPolicy: ActivityUIDismissalPolicy = .immediate
    ) {
        endAll(dismissalPolicy: dismissalPolicy)
    }
}
#endif
