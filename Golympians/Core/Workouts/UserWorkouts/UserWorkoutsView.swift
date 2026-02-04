//
//  WorkoutView.swift
//  Goalympians
//
//  Created by Bernard Scott on 4/3/25.
//

import SwiftUI
import FirebaseFirestore

struct UserWorkoutsView: View {
    
    @StateObject private var viewModel: WorkoutViewModel
    @State private var removalCandidateWorkout: DBWorkout?
    @State private var removeWorkoutAlert: Bool = false
    @State private var editMode = EditMode.inactive
    @State private var createWorkoutSheetIsPresented = false
    
    @Binding var path: NavigationPath
    let workoutDataService: WorkoutManagerProtocol
    
    init(
        workoutDataService: WorkoutManagerProtocol,
        path: Binding<NavigationPath>
    ) {
        self.workoutDataService = workoutDataService
        _path = path
        _viewModel = StateObject(wrappedValue: WorkoutViewModel(workoutDataService: workoutDataService))
    }
    
    var body: some View {
        List {
            ForEach(viewModel.workouts) { workout in
                NavigationLink(value: workout) {
                    VStack (alignment: .leading) {
                        Text(workout.name)
                            .font(.title2)
                        Text(workout.date.formatted())
                            .font(.caption)
                    }
                }
            }
            .onDelete { indexSet in
                removeWorkoutAlert = true
                for index in indexSet {
                    removalCandidateWorkout = viewModel.workouts[index]
                }
            }
            .deleteDisabled(!self.editMode.isEditing)
        }
        .navigationDestination(for: DBWorkout.self) { workout in
            EditWorkoutView(
                workout: viewModel.binding(for: workout.id)!,
                workoutDataService: viewModel.workoutDataService)
        }
        .navigationTitle("Workouts")
        .task {
            try? await viewModel.getAllWorkouts(descending: viewModel.dateOption?.dateDescending)
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                EditButton()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu("", systemImage: "arrow.up.arrow.down") {
                    ForEach(DateOption.allCases, id: \.self) { option in
                        Button {
                            Task {
                                try? await viewModel.filterDateOption(option: option)
                            }
                        } label: {
                            HStack {
                                if viewModel.dateOption == option {
                                    Image(systemName: "checkmark")
                                }
                                Text(option.prettyString)
                            }
                        }
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    createWorkoutSheetIsPresented = true
                } label: {
                    Text("Add Workout")
                }
                .sheet(isPresented: $createWorkoutSheetIsPresented) {
                    CreateWorkoutView(viewModel: viewModel, path: $path, isPresented: $createWorkoutSheetIsPresented)
                }
            }
        }
        .alert(
            "Remove Workout",
            isPresented: $removeWorkoutAlert
        ) {
            Button("Remove Workout", role: .destructive, action: removeWorkout)
            Button("Cancel", role: .cancel, action: {})
        } message: {
            Text("Are you sure you want to remove this workout? Removing it will delete all sets and exercises recorded in this workout.")
        }
        .environment(\.editMode, $editMode)
    }
    
    private func removeWorkout() {
        guard let removalCandidateWorkout else {
            return
        }
        
        Task {
            try await viewModel.removeWorkout(workoutId: removalCandidateWorkout.id)
            try await viewModel.getAllWorkouts(descending: viewModel.dateOption?.dateDescending)
        }
    }
}

#Preview {
    @Previewable @State var path = NavigationPath()
    @Previewable @StateObject var viewModel = WorkoutViewModel(workoutDataService: ProdWorkoutManager(workoutCollection: Firestore.firestore().collection("workouts")))
    NavigationStack {
        UserWorkoutsView(workoutDataService: ProdWorkoutManager(workoutCollection: Firestore.firestore().collection("workouts")), path: $path)
    }
}
