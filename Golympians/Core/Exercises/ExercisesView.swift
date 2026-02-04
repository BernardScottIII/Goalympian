//
//  ExercisesView.swift
//  Goalympians
//
//  Created by Bernard Scott on 4/3/25.
//

import SwiftUI
import FirebaseFirestore

struct ExercisesView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ExercisesViewModel
    @State private var targetMuscle = "Any Muscle"
    @State private var searchText = ""
    @State private var selectedExerciseId: String?
    
    @ObservedObject var activityViewModel: ActivityViewModel
    @State var navigationTitle: String
    @Binding var scrollTargetActivity: Int?
    let workoutDataService: WorkoutManagerProtocol
    let workoutId: String
    let usernames: [String]
    
    init(
        activityViewModel: ActivityViewModel,
        workoutDataService: WorkoutManagerProtocol,
        workoutId: String,
        usernames: [String],
        navigationTitle: String = "Exercises",
        scrollTargetActivity: Binding<Int?> = .constant(nil)
    ) {
        _viewModel = StateObject(wrappedValue: ExercisesViewModel(dataService: workoutDataService))
        self.activityViewModel = activityViewModel
        self.workoutDataService = workoutDataService
        self.workoutId = workoutId
        self.usernames = usernames
        self.navigationTitle = navigationTitle
        self._scrollTargetActivity = scrollTargetActivity
    }
    
    var body: some View {
        List {
            ForEach(viewModel.exercises.filter{
                searchText.isEmpty ? true : $0.name.localizedStandardContains(searchText)
            }, id: \.id) { exercise in
                HStack {
                    Text(exercise.name)
                        .truncationMode(.tail)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Button("", systemImage: "plus") {
                        if !activityViewModel.activities.contains(where: {$0.exercise.id == exercise.id}) {
                            viewModel.addWorkoutActivity(workoutId: workoutId, exercise: exercise)
                        } else {
                            guard let index = activityViewModel.activities.firstIndex(where: {$0.exercise.id == exercise.id}) else { return }
                            activityViewModel.addEmptyActivitySet(
                                workoutId: workoutId,
                                activity: activityViewModel.activities[index].activity
                            )
                            scrollTargetActivity = index
                        }
                        dismiss()
                    }
                    
                    // "It's good enough"
                    ZStack(alignment: .trailing) {
                        NavigationLink {
                            ExerciseDetailsView(viewModel: viewModel, exercise: viewModel.binding(for: exercise)!)
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.blue)
                        }
                        .scaledToFit()
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle(navigationTitle)
        .searchable(text: $searchText)
        .task {
            try? await viewModel.selectUsernames(usernames: usernames)
        }
        .withExercisesToolbar(viewModel: viewModel)
        
        NavigationLink("Create New Exercise") {
            CreateExerciseView(viewModel: viewModel)
        }
        .padding()
        .background(.golympiansPrimary)
        .clipShape(.buttonBorder)
        .foregroundStyle(.white)
        .fontWeight(.bold)
    }
}

#Preview {
    @Previewable let workoutDataService = ProdWorkoutManager(workoutCollection: Firestore.firestore().collection("workouts"))
    NavigationStack {
        ExercisesView(activityViewModel: ActivityViewModel(dataService: workoutDataService), workoutDataService: workoutDataService, workoutId: "SampleId", usernames: [
            UUID().uuidString,
            "global"
        ])
    }
}
