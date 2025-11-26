import Foundation
import SwiftData
import SwiftUI

@Model
final class Chapter: Identifiable {
    var id: String
    var title: String
    var totalPages: Int
    var orderIndex: Int
    var pagesStudied: Int
    var colorHex: String
    
    init(id: String = UUID().uuidString, title: String, totalPages: Int, orderIndex: Int, pagesStudied: Int = 0, colorHex: String = "#FFB3BA") {
        self.id = id
        self.title = title
        self.totalPages = totalPages
        self.orderIndex = orderIndex
        self.pagesStudied = pagesStudied
        self.colorHex = colorHex
    }
    
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}

@Model
final class StudyPlan {
    var dailyPageGoal: Int
    var startDate: Date
    var freeDays: [Int] // 1 = Sunday, 2 = Monday, etc.
    
    init(dailyPageGoal: Int = 10, startDate: Date = Date(), freeDays: [Int] = []) {
        self.dailyPageGoal = dailyPageGoal
        self.startDate = startDate
        self.freeDays = freeDays
    }
}

@Model
final class DailyLog {
    var date: Date
    var pagesLearned: Int
    var chapterId: String
    var isFreeDay: Bool
    
    init(date: Date, pagesLearned: Int, chapterId: String, isFreeDay: Bool = false) {
        self.date = date
        self.pagesLearned = pagesLearned
        self.chapterId = chapterId
        self.isFreeDay = isFreeDay
    }
}

// Helper for Color Hex
extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0

        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0

        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0

        } else {
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }
    
    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)

        if components.count >= 4 {
            a = Float(components[3])
        }

        if a != Float(1.0) {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}
