import SwiftUI

struct CalendarDayCell: View {
    let dayInfo: DayInfo
    let isSelected: Bool
    
    // Calendar utilities
    private let calendar = Calendar.current
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background Layer
            backgroundView
            
            // Content Layer
            // Icons/Indicators - Top Left
            VStack {
                HStack {
                    Spacer()
                    stateIcon
                        .font(.caption2)
                        .padding(4)
                }
                Spacer()
            }
            
            // Day Number - Bottom Center
            Text("\(calendar.component(.day, from: dayInfo.date))")
                .font(.caption)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(textColor)
                .padding(.bottom, 6)
        }
        .frame(height: 45) // Fixed height for consistency
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 2)
        )
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var backgroundView: some View {
        switch dayInfo.state {
        case .goalAchieved, .partialProgress, .missed:
            if let colorHex = dayInfo.chapterColor,
               let color = Color(hex: colorHex) {
                // If it's missed, we still show the color but maybe faint
                color.opacity(dayInfo.state == .goalAchieved ? 1.0 : 0.6)
            } else {
                Color.gray.opacity(0.3)
            }
            
        case .freeDay:
            Color.blue.opacity(0.1)
            
        case .notStarted:
            // Future scheduled tasks
            if let colorHex = dayInfo.chapterColor,
               let color = Color(hex: colorHex) {
                color.opacity(0.3)
            } else {
                Color.gray.opacity(0.05)
            }
            
        case .noActivity:
            Color.gray.opacity(0.1)
            
        case .notScheduled:
            Color.clear
        }
    }
    
    @ViewBuilder
    private var stateIcon: some View {
        switch dayInfo.state {
        case .goalAchieved:
            Image(systemName: "checkmark")
                .foregroundColor(.white)
                .padding(2)
                .background(Circle().fill(Color.green.opacity(0.8)))
            
        case .partialProgress:
            Circle()
                .fill(Color.yellow)
                .frame(width: 6, height: 6)
                .padding(2)
                .background(Circle().fill(Color.black.opacity(0.1)))
            
        case .missed:
            Circle()
                .fill(Color.red)
                .frame(width: 6, height: 6)
                .padding(2)
                .background(Circle().fill(Color.white.opacity(0.5))) 
            
        case .freeDay:
            Image(systemName: "sparkles")
                .foregroundColor(.blue)
            
        default:
            EmptyView()
        }
    }
    
    private var isToday: Bool {
        calendar.isDateInToday(dayInfo.date)
    }
    
    private var textColor: Color {
        // Contrast calculation could be better, but simple rule for now
        switch dayInfo.state {
        case .goalAchieved:
            return .white
        case .partialProgress:
            return .primary
        case .notStarted:
             return .primary
        default:
            return .primary
        }
    }
}
