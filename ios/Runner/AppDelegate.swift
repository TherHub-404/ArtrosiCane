import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let deepLinkChannelName = "com.company.app/deeplink"
  private let pendingInviteTokenKey = "pending_invite_token"
  private let pendingInviteLocationKey = "pending_invite_location"
  private let inviteHost = "artrosicane.vercel.app"
  private let invitePath = "/i"
  private let appGroupInfoKey = "APP_GROUP_ID"
  private let defaultAppGroupId = "group.com.artrosicase.artrosicane"
  private let appleAppClipHosts: Set<String> = ["appclip.apple.com", "apps.apple.com"]

  private var deepLinkChannel: FlutterMethodChannel?
  private var pendingDeepLinks: [String] = []
  private var isFlutterReady = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let didFinish = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    _ = ensureDeepLinkChannel()
    enqueuePendingTokenFromAppGroupIfNeeded()
    return didFinish
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    _ = ensureDeepLinkChannel()
  }

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL {
      handleIncomingUniversalLink(url)
      return true
    }

    return super.application(
      application,
      continue: userActivity,
      restorationHandler: restorationHandler
    )
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    handleIncomingUniversalLink(url)
    return super.application(app, open: url, options: options)
  }

  func handleIncomingUniversalLink(_ url: URL) {
    emitOrQueueDeepLink(url)
  }

  @discardableResult
  private func ensureDeepLinkChannel() -> Bool {
    if deepLinkChannel != nil {
      return true
    }

    guard
      let controller = window?.rootViewController as? FlutterViewController
    else {
      return false
    }

    let channel = FlutterMethodChannel(
      name: deepLinkChannelName,
      binaryMessenger: controller.binaryMessenger
    )

    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "NO_APP_DELEGATE", message: "AppDelegate unavailable", details: nil))
        return
      }

      switch call.method {
      case "consumeInitialLinks":
        self.isFlutterReady = true
        let buffered = self.pendingDeepLinks
        self.pendingDeepLinks.removeAll()
        result(buffered)
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    deepLinkChannel = channel
    return true
  }

  private func enqueuePendingTokenFromAppGroupIfNeeded() {
    let defaults = UserDefaults(suiteName: appGroupId()) ?? UserDefaults.standard
    let token = defaults.string(forKey: pendingInviteTokenKey)
    let pendingLocation = defaults.string(forKey: pendingInviteLocationKey)
    let normalizedToken = token?.trimmingCharacters(in: .whitespacesAndNewlines)
    let normalizedLocation = pendingLocation?.trimmingCharacters(in: .whitespacesAndNewlines)

    guard
      (normalizedToken?.isEmpty == false) ||
      (normalizedLocation?.isEmpty == false)
    else {
      return
    }

    defaults.removeObject(forKey: pendingInviteTokenKey)
    defaults.removeObject(forKey: pendingInviteLocationKey)
    defaults.synchronize()

    guard
      var components = URLComponents(string: "https://\(inviteHost)\(invitePath)")
    else {
      return
    }

    var queryItems: [URLQueryItem] = []
    if let normalizedToken, !normalizedToken.isEmpty {
      queryItems.append(URLQueryItem(name: "t", value: normalizedToken))
    }
    if let normalizedLocation, !normalizedLocation.isEmpty
    {
      queryItems.append(URLQueryItem(name: "location", value: normalizedLocation.lowercased()))
    }

    components.queryItems = queryItems
    guard let url = components.url else {
      return
    }

    emitOrQueueDeepLink(url)
  }

  private func appGroupId() -> String {
    let info = Bundle.main.infoDictionary ?? [:]
    let raw = (info[appGroupInfoKey] as? String)?
      .trimmingCharacters(in: .whitespacesAndNewlines)
    if let raw, !raw.isEmpty {
      return raw
    }
    return defaultAppGroupId
  }

  private func emitOrQueueDeepLink(_ url: URL) {
    _ = ensureDeepLinkChannel()

    guard url.scheme?.lowercased() == "https", let host = url.host?.lowercased() else {
      return
    }

    if host == inviteHost {
      let path = url.path
      let isInviteRoot = (path == invitePath || path == "\(invitePath)/")
      let isInviteSubpath = path.hasPrefix("\(invitePath)/")
      guard isInviteRoot || isInviteSubpath else {
        return
      }
    } else {
      guard appleAppClipHosts.contains(host), isRecognizedAppleAppClipLink(url) else {
        return
      }
    }

    let urlString = url.absoluteString
    if isFlutterReady, let channel = deepLinkChannel {
      channel.invokeMethod("onDeepLink", arguments: urlString)
    } else {
      pendingDeepLinks.append(urlString)
    }
  }

  private func isRecognizedAppleAppClipLink(_ url: URL) -> Bool {
    guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
      return false
    }

    let bundleId = components.queryItems?.first(where: { item in
      item.name == "p" || item.name == "app-clip-bundle-id"
    })?.value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

    return bundleId == "com.artrosicase.artrosicane.clip"
  }
}
