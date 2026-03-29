# LiveActivityCoordinator

### Functionality

- Provides functions to easily:
  - Start one or more live activities
  - Update a live activity by id
  - End a live activity by id
  - End all live activities

### Usage

```swift
struct Attributes: LiveActivityAttributes {
    struct ContentState: Codable, Hashable {}
}

final class ActivityHappener {
    private let coordinator = LiveActivityCoordinator<Attributes>()
    private var activityID: String?

    func startActivity() {
        let attributes = Attributes()
        let state = Attributes.ContentState()

        let result = coordinator.startActivity(
            with: attributes,
            showing: state
        )
        
        switch result {
            case .success(let id):
                activityID = id
            case .failure(let liveActivityError):
                handle(error: liveActivityError)
        }
    }

    func updateActivity() async {
        guard let activityID else { return }
        let _ = await coordinator.updateActivity(
            withID: activityID,
            to: Attributes.ContentState()
        )
    }
}
```
