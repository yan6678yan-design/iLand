import Foundation

/// The existing integrations remain available for local development only.
/// Enable in distribution only after the matching logo/data licenses are documented.
/// This is a compile-time policy, never a remote flag or App Review detection.
enum DistributionFeatures {
    static var thirdPartyCatalogs: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }
}
