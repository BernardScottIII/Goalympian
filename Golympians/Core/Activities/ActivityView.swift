//
//  ActivitiesView.swift
//  Goalympians
//
//  Created by Bernard Scott on 4/7/25.
//

import SwiftUI
import FirebaseFirestore

struct ActivityView: View {
    
    @State private var removeActivityAlert: Bool = false
    @State private var targetActivityId: String? = nil
    
    @ObservedObject var viewModel: ActivityViewModel
    @Binding var scrollTargetActivity: Int?
    var username: String
    let workoutDataService: WorkoutManagerProtocol
    let workoutId: String
    
    init(
        viewModel: ActivityViewModel,
        scrollTargetActivity: Binding<Int?>,
        username: String,
        workoutDataService: WorkoutManagerProtocol,
        workoutId: String
    ) {
        self.viewModel = viewModel
        self._scrollTargetActivity = scrollTargetActivity
        self.username = username
        self.workoutId = workoutId
        self.workoutDataService = workoutDataService
    }
    
    var body: some View {
        List {
            if viewModel.activities.isEmpty {
                Section {
                    NavigationLink {
                        ExercisesView(
                            activityViewModel: viewModel,
                            workoutDataService: workoutDataService,
                            workoutId: workoutId,
                            usernames: [username, "global"],
                            scrollTargetActivity: $scrollTargetActivity
                        )
                        .onDisappear {
                            viewModel.getAllActivities(workoutId: workoutId)
                        }
                    } label: {
                        Text("Add your first exercise to this workout!")
                    }
                }
            } else {
                ForEach($viewModel.activities, id: \.activity.id) { $workoutActivity in
                    let currentId = workoutActivity.activity.id
                    
                    Section {
                        HStack {
                            Text(workoutActivity.exercise.name)
                            
                            Spacer()
                            
                            Button("", systemImage: "plus") {
                                if viewModel.activities.count < 10 {
                                    viewModel.addEmptyActivitySet(workoutId: workoutId, activity: workoutActivity.activity)
                                }
                            }
                            Button("", systemImage: "trash") {
                                removeActivityAlert = true
                                targetActivityId = workoutActivity.activity.id
                            }
                        }
                        .buttonStyle(.plain)
                        
                        if viewModel.activities.contains(where: { $0.activity.id == currentId }) {
                            ActivitySetsView(
                                viewModel: viewModel,
                                workoutId: workoutId,
                                activity: $workoutActivity.activity
                            )
                        }
                    }
                    .id(workoutActivity.activity.id)
                }
            }
        }
        .onAppear {
            viewModel.getAllActivities(workoutId: workoutId)
        }
        .alert("Remove Exercise?", isPresented: $removeActivityAlert) {
            Button("Cancel", role: .cancel) {
                targetActivityId = nil
            }
            Button("Remove", role: .destructive) {
                viewModel.removeFromWorkout(workoutId: workoutId, activityId: targetActivityId!)
            }
        } message: {
            Text("Removing exercise will remove all sets recorded for exercise. Are you sure you want to continue?")
        }
    }
}

#Preview {
    @Previewable let workoutDataService = ProdWorkoutManager(workoutCollection: Firestore.firestore().collection("workouts"))
    @Previewable let username: String = ""
    @Previewable @State var scrollTargetActivity: Int? = nil
    NavigationStack {
        ActivityView(
            viewModel: ActivityViewModel(dataService: workoutDataService),
            scrollTargetActivity: $scrollTargetActivity,
            username: username,
            workoutDataService: workoutDataService,
            workoutId: "064F0044-E158-47F1-AAD3-3EA4DEA0C1BF"
        )
    }
}

