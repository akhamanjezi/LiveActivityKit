#if canImport(ActivityKit) && os(iOS)
import ActivityKit

public protocol LiveActivityAttributes: ActivityAttributes, Sendable
where ContentState: Sendable { }
#endif
