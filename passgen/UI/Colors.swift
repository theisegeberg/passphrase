import SwiftUI

extension Color {
    static let wongBlack = Color(red: 0, green: 0, blue: 0)
    static let wongOrange = Color(red: 230 / 255, green: 159 / 255, blue: 0)
    static let wongSkyBlue = Color(red: 86 / 255, green: 180 / 255, blue: 233 / 255)
    static let wongBluishGreen = Color(red: 0, green: 158 / 255, blue: 115 / 255)
    static let wongYellow = Color(red: 240 / 255, green: 228 / 255, blue: 66 / 255)
    static let wongBlue = Color(red: 0, green: 114 / 255, blue: 178 / 255)
    static let wongVermillion = Color(red: 213 / 255, green: 94 / 255, blue: 0)
    static let wongReddishPurple = Color(red: 204 / 255, green: 121 / 255, blue: 167 / 255)

    static func wongColors(scheme: ColorScheme) -> [Color] {
        switch scheme {
        case .light:
            [wongBluishGreen, wongOrange, wongBlue, wongVermillion, wongBluishGreen, wongOrange, wongBlue, wongVermillion]
        case .dark:
            [wongReddishPurple, wongYellow, wongSkyBlue, wongOrange, wongReddishPurple, wongYellow, wongSkyBlue, wongOrange]
        @unknown default:
            wongColors(scheme: .light)
        }
    }
}
