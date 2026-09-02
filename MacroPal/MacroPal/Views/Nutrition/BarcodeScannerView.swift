//
//  BarcodeScannerView.swift
//  MacroPal
//

import SwiftUI
import VisionKit
import Vision

/// Wraps `DataScannerViewController` for barcode scanning. Doesn't dismiss itself — the
/// presenting view controls the sheet/cover lifecycle so it can move straight into a
/// loading state after a scan.
struct BarcodeScannerView: UIViewControllerRepresentable {
    var onScan: (String) -> Void

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.ean13, .ean8, .upce])],
            qualityLevel: .balanced,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: false,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        try? controller.startScanning()
        return controller
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let onScan: (String) -> Void
        private var hasScanned = false

        init(onScan: @escaping (String) -> Void) {
            self.onScan = onScan
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard !hasScanned, let item = addedItems.first, case let .barcode(barcode) = item, let payload = barcode.payloadStringValue else { return }
            hasScanned = true
            dataScanner.stopScanning()
            onScan(payload)
        }
    }
}
