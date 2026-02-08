#if canImport(ActivityKit) && os(iOS)
import Foundation
import ActivityKit

@available(iOS 16.2, *)
public protocol LiveActivityCoordinating {
    associatedtype Attributes: LiveActivityAttributes
    
    var currentActivities: [Activity<Attributes>] { get }
    
    func startActivity(
        with attributes: Attributes,
        showing state: Activity<Attributes>.ContentState
    ) -> Result<Activity<Attributes>.ID, LiveActivityError>
    
    func updateActivity(
        withID activityID: Activity<Attributes>.ID,
        to state: Activity<Attributes>.ContentState,
        expiringOn staleDate: Date?,
        notifyWith alertConfig: AlertConfiguration?
    ) async -> Result<ActivityState, LiveActivityError>
    
    func stopActivity(
        withID activityID: Activity<Attributes>.ID,
        showing state: Activity<Attributes>.ContentState?,
        expiringOn staleDate: Date?,
        dismissalPolicy: ActivityUIDismissalPolicy
    ) async -> Result<ActivityState, LiveActivityError>
    
    func endAll(
        dismissalPolicy: ActivityUIDismissalPolicy
    ) async
}

@available(iOS 16.2, *)
public extension LiveActivityCoordinating {
    func updateActivity(
        withID activityID: Activity<Attributes>.ID,
        to state: Activity<Attributes>.ContentState,
        expiringOn staleDate: Date? = nil,
        notifyWith alertConfig: AlertConfiguration? = nil
    ) async -> Result<ActivityState, LiveActivityError> {
        await updateActivity(
            withID: activityID,
            to: state,
            expiringOn: staleDate,
            notifyWith: alertConfig
        )
    }
    
    func stopActivity(
        withID activityID: Activity<Attributes>.ID,
        showing state: Activity<Attributes>.ContentState? = nil,
        expiringOn staleDate: Date? = nil,
        dismissalPolicy: ActivityUIDismissalPolicy = .immediate
    ) async -> Result<ActivityState, LiveActivityError> {
        await stopActivity(
            withID: activityID,
            showing: state,
            expiringOn: staleDate,
            dismissalPolicy: dismissalPolicy
        )
    }
    
    func endAll(
        dismissalPolicy: ActivityUIDismissalPolicy = .immediate
    ) async {
        await endAll(dismissalPolicy: dismissalPolicy)
    }
}
#endif
