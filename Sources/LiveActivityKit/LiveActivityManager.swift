import Foundation
import WidgetKit
import ActivityKit

@available(iOS 16.1, *)
class LiveActivityManager<Attributes: LiveActivityAttributes>: LiveActivityManaging {
    private var liveActivities: [Activity<Attributes>] = []
    private var areActivitiesEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }
    
    func startActivity(with attributes: Attributes, showing state: Activity<Attributes>.ContentState) -> Result<ActivityState, LiveActivityError> {
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
    
    private func requestActivity(with attributes: Attributes, showing state: Activity<Attributes>.ContentState) throws -> Activity<Attributes> {
        try Activity.request(attributes: attributes,
                             contentState: state)
    }
    
    private func storeNewLiveActivity(_ activity: Activity<Attributes>) {
        liveActivities.append(activity)
    }
    
    private func activityIsInProgress(with attributes: Attributes) -> Bool {
        liveActivities.contains(where: { $0.attributes == attributes })
    }
}
