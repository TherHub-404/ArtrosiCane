import SwiftUI

@main
struct AppClipApp: App {
  @StateObject private var model = ClipInvocationModel()

  var body: some Scene {
    WindowGroup {
      ClipContentView(model: model)
        .onOpenURL { url in
          model.handleInvocationURL(url)
        }
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
          model.handle(userActivity: userActivity)
        }
    }
  }
}
