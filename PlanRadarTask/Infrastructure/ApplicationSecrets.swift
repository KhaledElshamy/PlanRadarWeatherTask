///
/// Provides strongly-typed access to the secrets that arrive via Info.plist substitutions.
/// The values are populated from `Secrets.xcconfig` (ignored in git) so they never live
/// directly in the repository history.
///
import Foundation

/// Accesses the API key supplied during the build.
enum ApplicationSecrets {
    /// The API key that must be supplied in `Secrets.xcconfig` and injected into Info.plist.
    static var apiKey: String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String,
              !value.isEmpty else {
            fatalError("API_KEY must be configured in Secrets.xcconfig for this build.")
        }
        return value
    }
}

