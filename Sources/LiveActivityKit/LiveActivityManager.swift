import Foundation
import WidgetKit
import ActivityKit

@available(iOS 16.2, *)
class LiveActivityManager<Attributes: LiveActivityAttributes>: LiveActivityManaging {
    private var liveActivities: [Activity<Attributes>] = []
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
        expiringOn staleDate: Date? = nil,
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
        await activity.update(content, alertConfiguration: alertConfig)
    }
    
    private func storeNewLiveActivity(
        _ activity: Activity<Attributes>
    ) {
        liveActivities.append(activity)
    }
    
    private func activityIsInProgress(
        with attributes: Attributes
    ) -> Bool {
        liveActivities.contains(where: { $0.attributes == attributes })
    }
    
    private func activeActivity(
        with attributes: Attributes
    ) -> Activity<Attributes>? {
        liveActivities.first(where: { $0.attributes == attributes })
    }
}
