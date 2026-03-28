#if canImport(ActivityKit) && os(iOS)
import ActivityKit

struct AnyLiveActivityHandle<Attributes: LiveActivityAttributes> {
    let id: Activity<Attributes>.ID

    private let activityStateProvider: () -> ActivityState
    private let updateHandler: (ActivityContent<Attributes.ContentState>, AlertConfiguration?) async -> Void
    private let endHandler: (ActivityContent<Attributes.ContentState>?, ActivityUIDismissalPolicy) async -> Void

    init(
        id: Activity<Attributes>.ID,
        activityState: @escaping () -> ActivityState,
        update: @escaping (ActivityContent<Attributes.ContentState>, AlertConfiguration?) async -> Void,
        end: @escaping (ActivityContent<Attributes.ContentState>?, ActivityUIDismissalPolicy) async -> Void
    ) {
        self.id = id
        self.activityStateProvider = activityState
        self.updateHandler = update
        self.endHandler = end
    }

    init(activity: Activity<Attributes>) {
        self.init(
            id: activity.id,
            activityState: { activity.activityState },
            update: { content, alertConfiguration in
                await activity.update(
                    content,
                    alertConfiguration: alertConfiguration
                )
            },
            end: { content, dismissalPolicy in
                await activity.end(
                    content,
                    dismissalPolicy: dismissalPolicy
                )
            }
        )
    }

    var activityState: ActivityState {
        activityStateProvider()
    }

    func update(
        _ content: ActivityContent<Attributes.ContentState>,
        alertConfiguration: AlertConfiguration?
    ) async {
        await updateHandler(content, alertConfiguration)
    }

    func end(
        _ content: ActivityContent<Attributes.ContentState>?,
        dismissalPolicy: ActivityUIDismissalPolicy
    ) async {
        await endHandler(content, dismissalPolicy)
    }
}

struct AnyLiveActivityClient<Attributes: LiveActivityAttributes> {
    private let areActivitiesEnabledProvider: () -> Bool
    private let activitiesProvider: () -> [AnyLiveActivityHandle<Attributes>]
    private let requestHandler: (Attributes, ActivityContent<Attributes.ContentState>) throws -> AnyLiveActivityHandle<Attributes>

    init(
        areActivitiesEnabled: @escaping () -> Bool,
        activities: @escaping () -> [AnyLiveActivityHandle<Attributes>],
        request: @escaping (Attributes, ActivityContent<Attributes.ContentState>) throws -> AnyLiveActivityHandle<Attributes>
    ) {
        self.areActivitiesEnabledProvider = areActivitiesEnabled
        self.activitiesProvider = activities
        self.requestHandler = request
    }

    var areActivitiesEnabled: Bool {
        areActivitiesEnabledProvider()
    }

    var activities: [AnyLiveActivityHandle<Attributes>] {
        activitiesProvider()
    }

    func request(
        attributes: Attributes,
        content: ActivityContent<Attributes.ContentState>
    ) throws -> AnyLiveActivityHandle<Attributes> {
        try requestHandler(attributes, content)
    }
}

extension AnyLiveActivityClient {
    static var activityKit: Self {
        Self(
            areActivitiesEnabled: {
                ActivityAuthorizationInfo().areActivitiesEnabled
            },
            activities: {
                Activity<Attributes>.activities.map {
                    AnyLiveActivityHandle(activity: $0)
                }
            },
            request: { attributes, content in
                let activity = try Activity.request(
                    attributes: attributes,
                    content: content
                )

                return AnyLiveActivityHandle(activity: activity)
            }
        )
    }
}
#endif
