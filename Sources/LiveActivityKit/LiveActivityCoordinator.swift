#if canImport(ActivityKit) && os(iOS)
import WidgetKit
import ActivityKit

@available(iOS 16.2, *)
open class LiveActivityCoordinator<Attributes: LiveActivityAttributes>: LiveActivityCoordinating {
    private var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }
    
    public init() {}
    
    public var currentActivities: [Activity<Attributes>] {
        Activity<Attributes>.activities
    }
    
    public func startActivity(
        with attributes: Attributes,
        showing state: Activity<Attributes>.ContentState
    ) -> Result<Activity<Attributes>.ID, LiveActivityError> {
        guard areActivitiesEnabled else {
            return .failure(.notEnabled)
        }
        
        do {
            let activity = try requestActivity(
                with: attributes,
                showing: state
            )
            
            return .success(activity.id)
        } catch {
            return .failure(.couldNotStart)
        }
    }
    
    public func updateActivity(
        withID activityID: Activity<Attributes>.ID,
        to state: Activity<Attributes>.ContentState,
        expiringOn staleDate: Date?,
        notifyWith alertConfig: AlertConfiguration?
    ) async -> Result<ActivityState, LiveActivityError> {
        guard areActivitiesEnabled else {
            return .failure(.notEnabled)
        }
        
        guard let activity = activeActivity(withID: activityID) else {
            return .failure(.activityNotFound)
        }
        
        let content = ActivityContent(
            state: state,
            staleDate: staleDate
        )
        
        await update(
            activity,
            with: content,
            notifyWith: alertConfig
        )
        
        return .success(activity.activityState)
    }
    
    public func stopActivity(
        withID activityID: Activity<Attributes>.ID,
        showing state: Activity<Attributes>.ContentState?,
        expiringOn staleDate: Date?,
        dismissalPolicy: ActivityUIDismissalPolicy
    ) async -> Result<ActivityState, LiveActivityError> {
        guard areActivitiesEnabled else {
            return .failure(.notEnabled)
        }
        
        guard let activity = activeActivity(withID: activityID) else {
            return .failure(.activityNotFound)
        }
        
        let content = state == nil 
        ? nil
        : ActivityContent(
            state: state!,
            staleDate: staleDate
        )
        
        await end(
            activity,
            with: content,
            dismissalPolicy: dismissalPolicy
        )
        
        return .success(activity.activityState)
    }
    
    public func endAll(
        dismissalPolicy: ActivityUIDismissalPolicy
    ) async {
        for activity in Activity<Attributes>.activities {
            await end(
                activity,
                dismissalPolicy: dismissalPolicy
            )
        }
    }
    
    private func requestActivity(
        with attributes: Attributes,
        showing state: Activity<Attributes>.ContentState
    ) throws -> Activity<Attributes> {
        try Activity.request(
            attributes: attributes,
            contentState: state
        )
    }
    
    private func update(
        _ activity: Activity<Attributes>,
        with content: ActivityContent<Attributes.ContentState>,
        notifyWith alertConfig: AlertConfiguration?
    ) async {
        await activity.update(
            content,
            alertConfiguration: alertConfig
        )
    }
    
    private func end(
        _ activity: Activity<Attributes>,
        with content: ActivityContent<Attributes.ContentState>? = nil,
        dismissalPolicy: ActivityUIDismissalPolicy
    ) async {
        await activity.end(
            content,
            dismissalPolicy: dismissalPolicy
        )
    }
    
    private func activeActivity(
        withID activityID: Activity<Attributes>.ID
    ) -> Activity<Attributes>? {
        currentActivities.first(where: { $0.id == activityID })
    }
}
#endif
