import WidgetKit
import ActivityKit

@available(iOS 16.2, *)
class LiveActivityManager<Attributes: LiveActivityAttributes>: LiveActivityManaging {
    private var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }
    
    var currentActivities: [Activity<Attributes>] {
        Activity<Attributes>.activities
    }
    
    func startActivity(
        with attributes: Attributes,
        showing state: Activity<Attributes>.ContentState
    ) -> Result<ActivityState, LiveActivityError> {
        guard areActivitiesEnabled else {
            return .failure(.notEnabled)
        }
        
        guard activityIsInProgress(with: attributes) == false else {
            return .failure(.alreadyInProgress)
        }
        
        do {
            let activity = try requestActivity(with: attributes, showing: state)
            return .success(activity.activityState)
        } catch {
            return .failure(.couldNotStart)
        }
    }
    
    func updateActivity(
        with attributes: Attributes,
        to state: Activity<Attributes>.ContentState,
        expiringOn staleDate: Date?,
        notifyWith alertConfig: AlertConfiguration?
    ) async -> Result<ActivityState, LiveActivityError> {
        guard areActivitiesEnabled else {
            return .failure(.notEnabled)
        }
        
        guard let activity = activeActivity(with: attributes) else {
            return .failure(.notActive)
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
    
    func stopActivity(
        with attributes: Attributes,
        showing state: Activity<Attributes>.ContentState?,
        expiringOn staleDate: Date?,
        dismissalPolicy: ActivityUIDismissalPolicy
    ) async -> Result<ActivityState, LiveActivityError> {
        guard areActivitiesEnabled else {
            return .failure(.notEnabled)
        }
        
        guard let activity = activeActivity(with: attributes) else {
            return .failure(.notActive)
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
    
    private func activityIsInProgress(
        with attributes: Attributes
    ) -> Bool {
        currentActivities.contains(where: { $0.attributes == attributes })
    }
    
    private func activeActivity(
        with attributes: Attributes
    ) -> Activity<Attributes>? {
        currentActivities.first(where: { $0.attributes == attributes })
    }
}
