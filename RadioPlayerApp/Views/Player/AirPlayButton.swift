import SwiftUI
import AVKit

/// Wraps AVRoutePickerView to show the system AirPlay / Bluetooth output picker.
struct AirPlayButton: UIViewRepresentable {
    var tintColor: UIColor = .label

    func makeUIView(context: Context) -> AVRoutePickerView {
        let picker = AVRoutePickerView()
        picker.tintColor = tintColor
        picker.activeTintColor = .systemOrange
        return picker
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        uiView.tintColor = tintColor
    }
}
