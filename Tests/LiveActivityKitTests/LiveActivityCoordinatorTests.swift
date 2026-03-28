#if canImport(ActivityKit) && os(iOS)
import ActivityKit
import Foundation
import Testing
@testable import LiveActivityKit

struct LiveActivityCoordinatorTests {
    @Test(arguments: disabledOperationCases)
    func givenActivitiesAreDisabled_whenOperationIsPerformed(
        _ operation: DisabledOperation,
        thenTheExpectedFailureIsReturned expected: LiveActivityError
    ) async {
        let environment = FakeLiveActivityEnvironment(
            areActivitiesEnabled: false
        )
        let coordinator = makeCoordinator(using: environment)

        switch operation {
        case .start:
            let result = coordinator.startActivity(
                with: .default,
                showing: .started
            )

            #expect(result == .failure(expected))

        case .update:
            let result = await coordinator.updateActivity(
                withID: "missing-activity",
                to: .updated,
                expiringOn: nil,
                notifyWith: nil
            )

            #expect(result == .failure(expected))

        case .stop:
            let result = await coordinator.stopActivity(
                withID: "missing-activity",
                showing: .finished,
                expiringOn: nil,
                dismissalPolicy: .immediate
            )

            #expect(result == .failure(expected))
        }
    }

    @Test(arguments: requestFailureCases)
    func givenRequestThrows_whenStartingActivity(
        _ input: StartScenario,
        _ thrownError: FakeRequestError,
        thenTheExpectedFailureIsReturned expected: LiveActivityError
    ) {
        let environment = FakeLiveActivityEnvironment(
            requestHandler: { _, _ in
                throw thrownError
            }
        )
        let coordinator = makeCoordinator(using: environment)

        let result = coordinator.startActivity(
            with: input.attributes,
            showing: input.state
        )

        #expect(result == .failure(expected))
    }

    @Test(arguments: requestSuccessCases)
    func givenRequestSucceeds_whenStartingActivity(
        _ input: StartScenario,
        thenTheActivityIDIsCorrect expectedID: Activity<TestAttributes>.ID,
        andTheStartRequestIsCorrect expectedRequest: RecordedRequest
    ) {
        let fakeActivity = FakeLiveActivity(
            id: expectedID,
            activityState: .active
        )
        let environment = FakeLiveActivityEnvironment(
            requestHandler: { _, _ in fakeActivity }
        )
        let coordinator = makeCoordinator(using: environment)

        let result = coordinator.startActivity(
            with: input.attributes,
            showing: input.state
        )

        #expect(result == .success(expectedID))
        #expect(environment.recordedRequests == [expectedRequest])
    }

    @Test(arguments: unknownActivityCases)
    func givenUnknownActivityID_whenUpdatingOrStopping(
        _ operation: UnknownActivityOperation,
        _ activityID: Activity<TestAttributes>.ID,
        thenTheExpectedFailureIsReturned expected: LiveActivityError
    ) async {
        let environment = FakeLiveActivityEnvironment()
        let coordinator = makeCoordinator(using: environment)

        switch operation {
        case .update:
            let result = await coordinator.updateActivity(
                withID: activityID,
                to: .updated,
                expiringOn: nil,
                notifyWith: nil
            )

            #expect(result == .failure(expected))

        case .stop:
            let result = await coordinator.stopActivity(
                withID: activityID,
                showing: .finished,
                expiringOn: nil,
                dismissalPolicy: .immediate
            )

            #expect(result == .failure(expected))
        }
    }

    @Test(arguments: updateCases)
    func givenKnownActivityID_whenUpdating(
        _ input: UpdateScenario,
        thenTheActivityState expectedState: ActivityState,
        andTheRecordedUpdateAreCorrect expectedUpdate: RecordedUpdate
    ) async {
        let activity = FakeLiveActivity(
            id: input.activityID,
            activityState: input.initialActivityState,
            updatedActivityState: input.resultingActivityState
        )
        let environment = FakeLiveActivityEnvironment(
            activities: [activity]
        )
        let coordinator = makeCoordinator(using: environment)

        let result = await coordinator.updateActivity(
            withID: input.activityID,
            to: input.updatedState,
            expiringOn: input.staleDate,
            notifyWith: input.alertConfiguration
        )

        #expect(result == .success(expectedState))
        #expect(activity.recordedUpdates == [expectedUpdate])
    }

    @Test(arguments: stopWithoutFinalStateCases)
    func givenKnownActivityID_whenStoppingWithoutFinalState(
        _ input: StopScenario,
        thenTheActivityState expectedState: ActivityState,
        andTheRecordedEndIsCorrect expectedEnd: RecordedEnd
    ) async {
        let activity = FakeLiveActivity(
            id: input.activityID,
            activityState: input.initialActivityState,
            endedActivityState: input.resultingActivityState
        )
        let environment = FakeLiveActivityEnvironment(
            activities: [activity]
        )
        let coordinator = makeCoordinator(using: environment)

        let result = await coordinator.stopActivity(
            withID: input.activityID,
            showing: input.finalState,
            expiringOn: input.staleDate,
            dismissalPolicy: input.dismissalPolicy
        )

        #expect(result == .success(expectedState))
        #expect(activity.recordedEnds == [expectedEnd])
    }

    @Test(arguments: stopWithFinalStateCases)
    func givenKnownActivityID_whenStoppingWithFinalState(
        _ input: StopScenario,
        thenTheActivityState expectedState: ActivityState,
        andTheRecordedEndIsCorrect expectedEnd: RecordedEnd
    ) async {
        let activity = FakeLiveActivity(
            id: input.activityID,
            activityState: input.initialActivityState,
            endedActivityState: input.resultingActivityState
        )
        let environment = FakeLiveActivityEnvironment(
            activities: [activity]
        )
        let coordinator = makeCoordinator(using: environment)

        let result = await coordinator.stopActivity(
            withID: input.activityID,
            showing: input.finalState,
            expiringOn: input.staleDate,
            dismissalPolicy: input.dismissalPolicy
        )

        #expect(result == .success(expectedState))
        #expect(activity.recordedEnds == [expectedEnd])
    }

    @Test(arguments: endAllCases)
    func givenMultipleActivities_whenEndingAll(
        _ input: EndAllScenario,
        thenTheRecordedEndsAreCorrect expectedRecordedEnds: [RecordedEnd]
    ) async {
        let activities = input.activityIDs.map {
            FakeLiveActivity(
                id: $0,
                activityState: .active
            )
        }
        let environment = FakeLiveActivityEnvironment(
            activities: activities
        )
        let coordinator = makeCoordinator(using: environment)

        await coordinator.endAll(
            dismissalPolicy: input.dismissalPolicy
        )

        let actualEnds = activities.flatMap(\.recordedEnds)
        #expect(actualEnds == expectedRecordedEnds)
    }
}

private extension LiveActivityCoordinatorTests {
    func makeCoordinator(
        using environment: FakeLiveActivityEnvironment
    ) -> LiveActivityCoordinator<TestAttributes> {
        LiveActivityCoordinator(
            client: environment.client()
        )
    }
}

fileprivate let disabledOperationCases: [(DisabledOperation, LiveActivityError)] = [
    (.start, .notEnabled),
    (.update, .notEnabled),
    (.stop, .notEnabled),
]

fileprivate let requestFailureCases: [(StartScenario, FakeRequestError, LiveActivityError)] = [
    (
        StartScenario(
            attributes: .default,
            state: .started
        ),
        .requestFailed,
        .couldNotStart
    ),
    (
        StartScenario(
            attributes: TestAttributes(name: "Horse school"),
            state: .updated
        ),
        .requestWasDenied,
        .couldNotStart
    ),
]

fileprivate let requestSuccessCases: [(StartScenario, Activity<TestAttributes>.ID, RecordedRequest)] = [
    (
        StartScenario(
            attributes: .default,
            state: .started
        ),
        "activity-1",
        RecordedRequest(
            attributes: .default,
            state: .started,
            staleDate: nil
        )
    ),
    (
        StartScenario(
            attributes: TestAttributes(name: "Pony training"),
            state: .updated
        ),
        "activity-2",
        RecordedRequest(
            attributes: TestAttributes(name: "Pony training"),
            state: .updated,
            staleDate: nil
        )
    ),
]

fileprivate let unknownActivityCases: [(UnknownActivityOperation, Activity<TestAttributes>.ID, LiveActivityError)] = [
    (.update, "missing-update-activity", .activityNotFound),
    (.stop, "missing-stop-activity", .activityNotFound),
]

fileprivate let updateCases: [(UpdateScenario, ActivityState, RecordedUpdate)] = {
    let staleDate = Date(timeIntervalSince1970: 1_731_234_567)
    let alertConfiguration = AlertConfiguration(
        title: "Update ready",
        body: "Your activity changed",
        sound: .default
    )

    return [
        (
            UpdateScenario(
                activityID: "activity-3",
                initialActivityState: .active,
                resultingActivityState: .active,
                updatedState: .updated,
                staleDate: nil,
                alertConfiguration: nil
            ),
            .active,
            RecordedUpdate(
                state: .updated,
                staleDate: nil,
                alertConfiguration: nil
            )
        ),
        (
            UpdateScenario(
                activityID: "activity-4",
                initialActivityState: .active,
                resultingActivityState: .stale,
                updatedState: .finished,
                staleDate: staleDate,
                alertConfiguration: alertConfiguration
            ),
            .stale,
            RecordedUpdate(
                state: .finished,
                staleDate: staleDate,
                alertConfiguration: alertConfiguration
            )
        ),
    ]
}()

fileprivate let stopWithoutFinalStateCases: [(StopScenario, ActivityState, RecordedEnd)] = {
    let dismissalDate = Date(timeIntervalSince1970: 1_800_000_060)

    return [
        (
            StopScenario(
                activityID: "activity-5",
                initialActivityState: .active,
                resultingActivityState: .ended,
                finalState: nil,
                staleDate: nil,
                dismissalPolicy: .immediate
            ),
            .ended,
            RecordedEnd(
                state: nil,
                staleDate: nil,
                dismissalPolicy: .immediate
            )
        ),
        (
            StopScenario(
                activityID: "activity-6",
                initialActivityState: .active,
                resultingActivityState: .dismissed,
                finalState: nil,
                staleDate: Date(timeIntervalSince1970: 1_800_000_000),
                dismissalPolicy: .after(dismissalDate)
            ),
            .dismissed,
            RecordedEnd(
                state: nil,
                staleDate: nil,
                dismissalPolicy: .after(dismissalDate)
            )
        ),
    ]
}()

fileprivate let stopWithFinalStateCases: [(StopScenario, ActivityState, RecordedEnd)] = {
    let firstDismissalDate = Date(timeIntervalSince1970: 1_900_000_060)
    let secondDismissalDate = Date(timeIntervalSince1970: 1_900_000_120)
    let firstStaleDate = Date(timeIntervalSince1970: 1_900_000_000)
    let secondStaleDate = Date(timeIntervalSince1970: 1_900_000_030)

    return [
        (
            StopScenario(
                activityID: "activity-7",
                initialActivityState: .active,
                resultingActivityState: .ended,
                finalState: .finished,
                staleDate: firstStaleDate,
                dismissalPolicy: .after(firstDismissalDate)
            ),
            .ended,
            RecordedEnd(
                state: .finished,
                staleDate: firstStaleDate,
                dismissalPolicy: .after(firstDismissalDate)
            )
        ),
        (
            StopScenario(
                activityID: "activity-8",
                initialActivityState: .stale,
                resultingActivityState: .dismissed,
                finalState: .archived,
                staleDate: secondStaleDate,
                dismissalPolicy: .after(secondDismissalDate)
            ),
            .dismissed,
            RecordedEnd(
                state: .archived,
                staleDate: secondStaleDate,
                dismissalPolicy: .after(secondDismissalDate)
            )
        ),
    ]
}()

fileprivate let endAllCases: [(EndAllScenario, [RecordedEnd])] = {
    let defaultScenario = EndAllScenario(
        activityIDs: ["activity-9", "activity-10", "activity-11"],
        dismissalPolicy: .default
    )
    let immediateScenario = EndAllScenario(
        activityIDs: ["activity-12", "activity-13"],
        dismissalPolicy: .immediate
    )

    return [
        (
            defaultScenario,
            defaultScenario.activityIDs.map { _ in
                RecordedEnd(
                    state: nil,
                    staleDate: nil,
                    dismissalPolicy: .default
                )
            }
        ),
        (
            immediateScenario,
            immediateScenario.activityIDs.map { _ in
                RecordedEnd(
                    state: nil,
                    staleDate: nil,
                    dismissalPolicy: .immediate
                )
            }
        ),
    ]
}()

enum DisabledOperation: String, CaseIterable, Sendable {
    case start
    case update
    case stop
}

enum UnknownActivityOperation: String, CaseIterable, Sendable {
    case update
    case stop
}

enum FakeRequestError: Error, Sendable {
    case requestFailed
    case requestWasDenied
}

struct StartScenario: Sendable {
    let attributes: TestAttributes
    let state: TestAttributes.ContentState
}

struct UpdateScenario: Sendable {
    let activityID: Activity<TestAttributes>.ID
    let initialActivityState: ActivityState
    let resultingActivityState: ActivityState
    let updatedState: TestAttributes.ContentState
    let staleDate: Date?
    let alertConfiguration: AlertConfiguration?
}

struct StopScenario: Sendable {
    let activityID: Activity<TestAttributes>.ID
    let initialActivityState: ActivityState
    let resultingActivityState: ActivityState
    let finalState: TestAttributes.ContentState?
    let staleDate: Date?
    let dismissalPolicy: ActivityUIDismissalPolicy
}

struct EndAllScenario: Sendable {
    let activityIDs: [Activity<TestAttributes>.ID]
    let dismissalPolicy: ActivityUIDismissalPolicy
}

struct RecordedRequest: Equatable, Sendable {
    let attributes: TestAttributes
    let state: TestAttributes.ContentState
    let staleDate: Date?
}

struct RecordedUpdate: Equatable, Sendable {
    let state: TestAttributes.ContentState
    let staleDate: Date?
    let alertConfiguration: AlertConfiguration?
}

struct RecordedEnd: Equatable, Sendable {
    let state: TestAttributes.ContentState?
    let staleDate: Date?
    let dismissalPolicy: ActivityUIDismissalPolicy
}

struct TestAttributes: LiveActivityAttributes, Equatable {
    struct ContentState: Codable, Equatable, Hashable, Sendable {
        let status: String
    }

    let name: String

    static let `default` = Self(
        name: "Fishing lessons"
    )
}

extension TestAttributes.ContentState {
    static let started = Self(status: "started")
    static let updated = Self(status: "updated")
    static let finished = Self(status: "finished")
    static let archived = Self(status: "archived")
}

final class FakeLiveActivity {
    let id: Activity<TestAttributes>.ID

    private let updatedActivityState: ActivityState
    private let endedActivityState: ActivityState

    private(set) var activityState: ActivityState
    private(set) var recordedUpdates: [RecordedUpdate] = []
    private(set) var recordedEnds: [RecordedEnd] = []

    init(
        id: Activity<TestAttributes>.ID,
        activityState: ActivityState,
        updatedActivityState: ActivityState? = nil,
        endedActivityState: ActivityState = .ended
    ) {
        self.id = id
        self.activityState = activityState
        self.updatedActivityState = updatedActivityState ?? activityState
        self.endedActivityState = endedActivityState
    }

    var handle: AnyLiveActivityHandle<TestAttributes> {
        AnyLiveActivityHandle(
            id: id,
            activityState: { self.activityState },
            update: { content, alertConfiguration in
                self.recordedUpdates.append(
                    RecordedUpdate(
                        state: content.state,
                        staleDate: content.staleDate,
                        alertConfiguration: alertConfiguration
                    )
                )
                self.activityState = self.updatedActivityState
            },
            end: { content, dismissalPolicy in
                self.recordedEnds.append(
                    RecordedEnd(
                        state: content?.state,
                        staleDate: content?.staleDate,
                        dismissalPolicy: dismissalPolicy
                    )
                )
                self.activityState = self.endedActivityState
            }
        )
    }
}

final class FakeLiveActivityEnvironment {
    var areActivitiesEnabled: Bool
    var activities: [FakeLiveActivity]
    var recordedRequests: [RecordedRequest] = []

    private let requestHandler: (TestAttributes, ActivityContent<TestAttributes.ContentState>) throws -> FakeLiveActivity

    init(
        areActivitiesEnabled: Bool = true,
        activities: [FakeLiveActivity] = [],
        requestHandler: @escaping (TestAttributes, ActivityContent<TestAttributes.ContentState>) throws -> FakeLiveActivity = { _, _ in
            throw FakeRequestError.requestFailed
        }
    ) {
        self.areActivitiesEnabled = areActivitiesEnabled
        self.activities = activities
        self.requestHandler = requestHandler
    }

    func client() -> AnyLiveActivityClient<TestAttributes> {
        AnyLiveActivityClient(
            areActivitiesEnabled: { self.areActivitiesEnabled },
            activities: {
                self.activities.map(\.handle)
            },
            request: { attributes, content in
                self.recordedRequests.append(
                    RecordedRequest(
                        attributes: attributes,
                        state: content.state,
                        staleDate: content.staleDate
                    )
                )

                return try self.requestHandler(attributes, content).handle
            }
        )
    }
}
#endif
