import SwiftUI

struct ClipContentView: View {
  @ObservedObject var model: ClipInvocationModel
  @Environment(\.openURL) private var openURL

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Accesso invito")
        .font(.title2).bold()

      Text(model.statusText)
        .font(.body)

      if let token = model.token {
        Text("Token: \(token)")
          .font(.caption)
          .foregroundColor(.secondary)
      }

      if let location = model.location {
        Text("Location: \(location)")
          .font(.caption2)
          .foregroundColor(.secondary)
      }

      if let error = model.errorText {
        Text(error)
          .font(.footnote)
          .foregroundColor(.red)
      }

      Button {
        model.showGetFullApp(openURL: openURL)
      } label: {
        Text("Get full app")
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(10)
      }
      .disabled(model.isValidating)

      Spacer()
    }
    .padding(20)
  }
}
