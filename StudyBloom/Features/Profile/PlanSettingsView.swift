import SwiftUI
import SwiftData

struct PlanSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Query private var plans: [StudyPlan]
    
    @State private var localDailyGoal: Int = 10
    @State private var localFreeDays: Set<Int> = []
    @State private var hasInitialized = false
    
    let weekdays = [
        (1, "S"), (2, "M"), (3, "T"), (4, "W"), (5, "T"), (6, "F"), (7, "S")
    ]
    
    var currentPlan: StudyPlan? {
        plans.first
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Daily Goal")) {
                    VStack {
                        HStack {
                            Text("Pages per day")
                            Spacer()
                            Text("\(localDailyGoal)")
                                .bold()
                                .foregroundStyle(.purple)
                        }
                        Slider(value: Binding(
                            get: { Double(localDailyGoal) },
                            set: { localDailyGoal = Int($0) }
                        ), in: 1...100, step: 1)
                            .tint(.purple)
                    }
                }
                
                Section(header: Text("Free Days")) {
                    HStack {
                        ForEach(weekdays, id: \.0) { day in
                            Text(day.1)
                                .font(.caption)
                                .fontWeight(.bold)
                                .frame(width: 30, height: 30)
                                .background(localFreeDays.contains(day.0) ? Color.purple : Color.gray.opacity(0.2))
                                .foregroundColor(localFreeDays.contains(day.0) ? .white : .primary)
                                .clipShape(Circle())
                                .onTapGesture {
                                    if localFreeDays.contains(day.0) {
                                        localFreeDays.remove(day.0)
                                    } else {
                                        localFreeDays.insert(day.0)
                                    }
                                }
                            if day.0 != 7 { Spacer() }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Button("Save Settings") {
                        saveSettings()
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(.purple)
                }
            }
            .navigationTitle("Study Plan")
            .task {
                if !hasInitialized {
                    loadSettings()
                    hasInitialized = true
                }
            }
        }
    }
    
    private func loadSettings() {
        if let plan = currentPlan {
            localDailyGoal = plan.dailyPageGoal
            localFreeDays = Set(plan.freeDays)
        }
    }

    
    private func saveSettings() {
        if let plan = currentPlan {
            plan.dailyPageGoal = localDailyGoal
            plan.freeDays = Array(localFreeDays)
            try? modelContext.save()
        } else {
            let newPlan = StudyPlan(
                dailyPageGoal: localDailyGoal,
                freeDays: Array(localFreeDays)
            )
            modelContext.insert(newPlan)
        }
        dismiss()
    }
}

#Preview {
    PlanSettingsView()
        .modelContainer(for: StudyPlan.self, inMemory: true)
}
