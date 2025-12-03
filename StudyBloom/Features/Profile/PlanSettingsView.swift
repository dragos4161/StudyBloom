import SwiftUI

struct PlanSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var dataService: DataService
    
    private var currentPlan: StudyPlan? { dataService.studyPlan }
    
    @State private var localDailyGoal: Int = 10
    @State private var localFreeDays: Set<Int> = []
    @State private var hasInitialized = false
    
    let weekdays = [
        (1, "S"), (2, "M"), (3, "T"), (4, "W"), (5, "T"), (6, "F"), (7, "S")
    ]
    

    
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
        guard let userId = dataService.currentUserId else { return }
        
        var planToSave: StudyPlan
        
        if let plan = currentPlan {
            planToSave = plan
            planToSave.dailyPageGoal = localDailyGoal
            planToSave.freeDays = Array(localFreeDays)
        } else {
            planToSave = StudyPlan(
                userId: userId,
                dailyPageGoal: localDailyGoal,
                freeDays: Array(localFreeDays)
            )
        }
        
        Task {
            try? await dataService.saveStudyPlan(planToSave)
            dismiss()
        }
    }
}

#Preview {
    PlanSettingsView()
        .environmentObject(DataService())
}
