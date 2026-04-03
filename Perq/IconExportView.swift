import SwiftUI

/// Temporary one-shot view for exporting the app icon PNG.
/// Usage:
///   1. In PerqApp.swift, replace ContentView() with IconExportView()
///   2. Run on simulator or device
///   3. Tap "Export", then "Share" → AirDrop to your Mac
///   4. Drag the PNG into AppIcon.appiconset in Xcode
///   5. Revert PerqApp.swift back to ContentView()

struct IconExportView: View {
    @State private var exportURL: URL?

    var body: some View {
        ZStack {
            Color.perqInk.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                PerqIcon(size: 200, style: .full)

                VStack(spacing: 8) {
                    Text("Icon Exporter")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.perqGhost)

                    Text("Renders PerqIcon at 1024 × 1024 pt, scale 1.0")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if exportURL == nil {
                    Button(action: exportIcon) {
                        Label("Export 1024 × 1024 PNG", systemImage: "square.and.arrow.down")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .background(Color.perqViolet)
                            .cornerRadius(14)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.perqMint)

                        Text("Exported — share it to your Mac")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        if let url = exportURL {
                            ShareLink(item: url, preview: SharePreview("perq-icon-1024.png")) {
                                Label("Share / AirDrop", systemImage: "square.and.arrow.up")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 28)
                                    .padding(.vertical, 14)
                                    .background(Color.perqSky.opacity(0.85))
                                    .cornerRadius(14)
                            }

                            Text(url.path)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                    }
                }

                Spacer()

                Text("Delete IconExportView.swift after use")
                    .font(.caption2)
                    .foregroundColor(.perqAmber.opacity(0.7))
                    .padding(.bottom, 8)
            }
            .padding()
        }
    }

    private func exportIcon() {
        let renderer = ImageRenderer(content: PerqIcon(size: 1024, style: .full))
        renderer.scale = 1.0
        guard let uiImage = renderer.uiImage, let data = uiImage.pngData() else { return }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("perq-icon-1024.png")
        try? data.write(to: url)
        exportURL = url
        print("✅ Icon exported to: \(url.path)")
    }
}

#Preview {
    IconExportView()
}
