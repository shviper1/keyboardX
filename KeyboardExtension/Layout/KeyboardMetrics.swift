import UIKit

/// Geometry approximating the stock iPhone keyboard (iOS 15–18).
struct KeyboardMetrics: Equatable {
    let rowPitch: CGFloat          // row height including vertical gap
    let keyHeight: CGFloat
    let horizontalGap: CGFloat
    let sideInset: CGFloat
    let cornerRadius: CGFloat
    let barHeight: CGFloat
    let letterFontSize: CGFloat
    let functionFontSize: CGFloat
    let isLandscape: Bool

    var keysHeight: CGFloat { rowPitch * 4 }
    var totalHeight: CGFloat { barHeight + keysHeight }
    var verticalGap: CGFloat { rowPitch - keyHeight }

    static let portrait = KeyboardMetrics(
        rowPitch: 54, keyHeight: 42, horizontalGap: 6, sideInset: 3, cornerRadius: 5,
        barHeight: 44, letterFontSize: 22.5, functionFontSize: 16, isLandscape: false)

    static let landscape = KeyboardMetrics(
        rowPitch: 40.5, keyHeight: 32, horizontalGap: 6, sideInset: 3, cornerRadius: 5,
        barHeight: 38, letterFontSize: 22, functionFontSize: 15, isLandscape: true)

    var letterFont: UIFont { .systemFont(ofSize: letterFontSize, weight: .light) }
    var uppercaseLetterFont: UIFont { .systemFont(ofSize: letterFontSize, weight: .regular) }
    var functionFont: UIFont { .systemFont(ofSize: functionFontSize, weight: .regular) }
    var symbolConfiguration: UIImage.SymbolConfiguration {
        .init(pointSize: functionFontSize + 4, weight: .regular)
    }
}
