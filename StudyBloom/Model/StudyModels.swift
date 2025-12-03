import Foundation
import SwiftUI

// MARK: - Chapter Model
struct Chapter: Identifiable, Codable, Equatable {
    var id: String
    var userId: String
    var title: String
    var totalPages: Int
    var orderIndex: Int
    var pagesStudied: Int
    var colorHex: String
    var createdAt: Date?
    var updatedAt: Date?
    
    init(id: String = UUID().uuidString, userId: String, title: String, totalPages: Int, orderIndex: Int, pagesStudied: Int = 0, colorHex: String = "#FFB3BA") {
        self.id = id
        self.userId = userId
        self.title = title
        self.totalPages = totalPages
        self.orderIndex = orderIndex
        self.pagesStudied = pagesStudied
        self.colorHex = colorHex
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var color: Color {
        Color(hex: colorHex) ?? .blue
    }
}

// MARK: - StudyPlan Model
struct StudyPlan: Identifiable, Codable, Equatable {
    var id: String?
    var userId: String
    var dailyPageGoal: Int
    var startDate: Date
    var freeDays: [Int] // 1 = Sunday, 2 = Monday, etc.
    var createdAt: Date?
    var updatedAt: Date?
    
    init(id: String? = nil, userId: String, dailyPageGoal: Int = 10, startDate: Date = Date(), freeDays: [Int] = []) {
        self.id = id
        self.userId = userId
        self.dailyPageGoal = dailyPageGoal
        self.startDate = startDate
        self.freeDays = freeDays
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - DailyLog Model
struct DailyLog: Identifiable, Codable, Equatable {
    var id: String?
    var userId: String
    var date: Date
    var pagesLearned: Int
    var chapterId: String
    var isFreeDay: Bool
    var createdAt: Date?
    
    init(id: String? = nil, userId: String, date: Date, pagesLearned: Int, chapterId: String, isFreeDay: Bool = false) {
        self.id = id
        self.userId = userId
        self.date = date
        self.pagesLearned = pagesLearned
        self.chapterId = chapterId
        self.isFreeDay = isFreeDay
        self.createdAt = Date()
    }
}

// MARK: - Helper for Color Hex
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
