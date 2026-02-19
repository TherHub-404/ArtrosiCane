import UIKit

// Optional for scene-based iOS templates.
// If your Info.plist defines UIApplicationSceneManifest, add this file to Runner target.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    guard
      userActivity.activityType == NSUserActivityTypeBrowsingWeb,
      let url = userActivity.webpageURL,
      let delegate = UIApplication.shared.delegate as? AppDelegate
    else {
      return
    }

    delegate.handleIncomingUniversalLink(url)
  }
}
