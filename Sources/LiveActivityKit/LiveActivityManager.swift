import Foundation
import WidgetKit
import ActivityKit

@available(iOS 16.2, *)
class LiveActivityManager<Attributes: LiveActivityAttributes>: LiveActivityManaging {
    private var currentActivites: [Activity<Attributes>] = []
    private var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
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
            storeNewLiveActivity(activity)
            
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
        
        updateActive(activity)
        
        return .success(activity.activityState)
    }
    
    func stopActivity(
        with attributes: Attributes,
        showing state: Activity<Attributes>.ContentState,
        expiringOn staleDate: Date?,
        dismissalPolicy: ActivityUIDismissalPolicy
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
        
        await end(
            activity,
            with: content,
            dismissalPolicy: dismissalPolicy
        )
        
        removeEnded(activity)
        
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
        with content: ActivityContent<Attributes.ContentState>,
        dismissalPolicy: ActivityUIDismissalPolicy
    ) async {
        await activity.end(
            content,
            dismissalPolicy: dismissalPolicy
        )
    }
    
    private func storeNewLiveActivity(
        _ activity: Activity<Attributes>
    ) {
        currentActivites.append(activity)
    }
    
    private func activityIsInProgress(
        with attributes: Attributes
    ) -> Bool {
        currentActivites.contains(where: { $0.attributes == attributes })
    }
    
    private func activeActivity(
        with attributes: Attributes
    ) -> Activity<Attributes>? {
        currentActivites.first(where: { $0.attributes == attributes })
    }
    
    private func updateActive(
        _ activity: Activity<Attributes>
    ) {
        guard let index = currentActivitiesIndex(for: activity) else { return }
        currentActivites[index] = activity
    }
    
    private func currentActivitiesIndex(for activity: Activity<Attributes>) -> Int? {
        currentActivites.firstIndex(where: { $0.attributes == activity.attributes })
    }
    
    private func removeEnded(
        _ activity: Activity<Attributes>
    ) {
        currentActivites.removeAll(where: { $0.attributes == activity.attributes })
    }
}
