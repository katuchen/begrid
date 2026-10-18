import SwiftUI

struct OfflineBanner: View {
    var body: some View {
        Label("Offline, showing saved photos", systemImage: "wifi.slash")
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(.regularMaterial, in: Capsule())
            .padding(.bottom, 8)
    }
}
