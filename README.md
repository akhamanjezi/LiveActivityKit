# LiveActivityCoordinator

### Functionality

- Provides functions to easily:
  - Start a live activity
  - Update a live activity
  - End a live activity
  - End all live activities

### Configuration

- No advanced configuration required
  
### Recommendations

I recommend you use the protocol `LiveActiviyCoordinating` to type cast an object when instantiating--better yet, use DI. Use of the protocol has the following advantages:
- Extension provides defaults
- can provide your own implementation at a later point without changing all the places you consume the to-be-replaced `LiveActivityCoordinator`

### Usage

```swift
class Attributes: LiveActivityAttributes {
    struct Coordinator: Codable, Hashable {}
}

class ActivityHapppener {
    private let coordiator: LiveActivityCoordinating

    init(
        coordinator: LiveActivityCoordinating = LiveActivityCoordinator()
    )
    
    func startActivity() {
        let attributes: Attributes = DummyLiveActivityAttributes()
        let state: Attributes.ContentState = DummyContentState()

        let result = coordinator.startActivity(
            with: attributes,
            showing: state
        )
        
        switch result {
            case .success(let activityState):
            doSomething(with: activityState)
            case .failure(let liveActivityError):
            handle(error: liveActivityError)
        }
    }
}
```