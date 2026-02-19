import Foundation
import StoreKit
import SwiftUI
import UIKit

@MainActor
final class ClipInvocationModel: ObservableObject {
  @Published var statusText: String = "In attesa del link..."
  @Published var isValidating = false
  @Published var token: String?
  @Published var location: String?
  @Published var errorText: String?

  private let inviteHost = "artrosicane.vercel.app"
  private let invitePath = "/i"
  private let validateBaseUrl = "https://api.example.com"
  private let appGroupId = "group.com.company.app"
  private let pendingTokenKey = "pending_invite_token"
  private let pendingLocationKey = "pending_invite_location"
  private let fullAppAppStoreId = "1234567890" // Replace with your App Store ID

  func handle(userActivity: NSUserActivity) {
    guard
      userActivity.activityType == NSUserActivityTypeBrowsingWeb,
      let url = userActivity.webpageURL
    else {
      return
    }

    handleInvocationURL(url)
  }

  func handleInvocationURL(_ url: URL) {
    guard let inviteLink = parseInviteLink(from: url) else {
      statusText = "Link non valido"
      errorText = "Formato link non riconosciuto"
      return
    }

    token = inviteLink.token
    location = inviteLink.location
    Task {
      await validateAndPersist(token: inviteLink.token, location: inviteLink.location)
    }
  }

  func showGetFullApp(openURL: OpenURLAction) {
    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
      let config = SKOverlay.AppConfiguration(
        appIdentifier: fullAppAppStoreId,
        position: .bottom
      )
      config.userDismissible = true
      SKOverlay(configuration: config).present(in: scene)
      return
    }

    guard let appStoreUrl = URL(string: "https://apps.apple.com/app/id\(fullAppAppStoreId)") else {
      return
    }
    openURL(appStoreUrl)
  }

  private func validateAndPersist(token: String, location: String?) async {
    isValidating = true
    errorText = nil
    statusText = "Verifica token in corso..."

    do {
      let isValid = try await validate(token: token)
      guard isValid else {
        statusText = "Token non valido"
        errorText = "Il token potrebbe essere scaduto o già usato"
        isValidating = false
        return
      }

      let defaults = UserDefaults(suiteName: appGroupId)
      defaults?.set(token, forKey: pendingTokenKey)
      defaults?.set(location, forKey: pendingLocationKey)
      defaults?.set(Date().timeIntervalSince1970, forKey: "pending_invite_token_saved_at")
      defaults?.synchronize()

      statusText = "Token valido. Installa l'app completa."
    } catch {
      statusText = "Errore di rete"
      errorText = error.localizedDescription
    }

    isValidating = false
  }

  private func validate(token: String) async throws -> Bool {
    guard
      let encoded = token.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
      let url = URL(string: "\(validateBaseUrl)/validate?t=\(encoded)")
    else {
      throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.timeoutInterval = 10
    request.setValue("application/json", forHTTPHeaderField: "Accept")

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    guard 200 ..< 300 ~= httpResponse.statusCode else {
      return false
    }

    let payload = try JSONSerialization.jsonObject(with: data, options: [])
    guard
      let json = payload as? [String: Any],
      let valid = json["valid"] as? Bool
    else {
      throw URLError(.cannotParseResponse)
    }

    return valid
  }

  private func parseInviteLink(from url: URL) -> (token: String, location: String?)? {
    guard
      url.scheme?.lowercased() == "https",
      url.host?.lowercased() == inviteHost
    else {
      return nil
    }

    let normalizedPath = url.path.hasSuffix("/") && url.path.count > 1
      ? String(url.path.dropLast())
      : url.path
    guard normalizedPath == invitePath else {
      return nil
    }

    guard
      let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
      let token = components.queryItems?.first(where: { $0.name == "t" })?.value,
      !token.isEmpty
    else {
      return nil
    }

    let location = components.queryItems?
      .first(where: { $0.name == "location" })?
      .value?
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .lowercased()

    return (token, (location?.isEmpty ?? true) ? nil : location)
  }
}
