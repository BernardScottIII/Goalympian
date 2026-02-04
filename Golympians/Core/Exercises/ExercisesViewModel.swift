//
//  ExercisesViewModel.swift
//  Goalympians
//
//  Created by Bernard Scott on 4/3/25.
//

import SwiftUI
import FirebaseFirestore

@MainActor
final class ExercisesViewModel: ObservableObject {
    
    @Published private(set) var exercises: [APIExercise] = []
    @Published var selectedFilter: FilterOption? = .noFilter
    @Published var selectedMuscle: MuscleOption? = .allMuscles
    @Published var selectedEquipment: EquipmentOption? = .noEquipment
    @Published var usernames: [String]? = nil
    
    let dataService: WorkoutManagerProtocol
    
    init(dataService: WorkoutManagerProtocol) {
        self.dataService = dataService
    }
    
    func addWorkoutActivity(workoutId: String, exercise: APIExercise) {
        Task {
            try await dataService.addWorkoutActivity(workoutId: workoutId, exercise: exercise)
        }
    }
    
    func filterSelectedOption(option: FilterOption) async throws {
        self.selectedFilter = option
        try await self.getExercises()
    }
    
    func filterEquipmentOption(equipment: EquipmentOption) async throws {
        self.selectedEquipment = equipment
        try await self.getExercises()
    }
    
    func muscleSelected(muscle: MuscleOption) async throws {
        self.selectedMuscle = muscle
        try await self.getExercises()
    }
    
    func selectUsernames(usernames: [String]) async throws {
        self.usernames = usernames
        try await self.getExercises()
    }
    
    func getExercises() async throws {
        self.exercises = try await ExerciseManager.shared.getAllExercises(nameDescending: selectedFilter?.nameDescending, forMuscle: selectedMuscle?.rawValue, usingEquipment: selectedEquipment?.rawValue, usernames: usernames)
    }
    
    func removeUserExercise(exercise: APIExercise) async throws {
        let userId = try AuthenticationManager.shared.getAuthenticatedUser().uid
        let username = try await UserManager.shared.getUser(userId: userId).username
        
        try await ExerciseManager.shared.removeUserExercise(username: username, exercise: exercise)
    }
    
    func binding(for exercise: APIExercise) -> Binding<APIExercise>? {
        guard let index = exercises.firstIndex(where: {$0.id == exercise.id! }) else {
            return nil
        }
        
        return Binding(
            get: {self.exercises[index]},
            set: {self.exercises[index] = $0}
        )
    }
    
    func updateExercise(exercise: APIExercise) async throws {
        try await ExerciseManager.shared.updateExercise(exercise: exercise)
    }
    
    func uploadExercise(
        id: String,
        name: String,
        equipment: EquipmentOption,
        customEquipment: String?,
        target: MuscleOption,
        secondaryMuscles: [String],
        instructions: [String],
        gifUrl: String,
        setType: SetType
    ) async throws {
        let userId = try AuthenticationManager.shared.getAuthenticatedUser().uid
        let username = try await UserManager.shared.getUser(userId: userId).username

        let savedEquipment: String
        if equipment == .customEquipment {
            savedEquipment = customEquipment ?? "custom"
        } else {
            savedEquipment = equipment.rawValue
        }

        try await ExerciseManager.shared.uploadExercise(exercise: APIExercise(
            id: UUID().uuidString,
            name: name,
            equipment: savedEquipment,
            target: target,
            secondaryMuscles: ["No secondary muscles"],
            instructions: instructions,
            gifUrl: "no url",
            username: username,
            setType: setType
        ))
    }
}

