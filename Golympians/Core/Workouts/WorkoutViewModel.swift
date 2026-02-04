//
//  WorkoutViewModel.swift
//  Goalympians
//
//  Created by Bernard Scott on 4/3/25.
//

//import Foundation
import SwiftUI

@MainActor
final class WorkoutViewModel: ObservableObject {
    
    @Published private(set) var workouts: [DBWorkout] = []
    @Published private(set) var dateOption: DateOption? = .dateDescending
    let workoutDataService: WorkoutManagerProtocol
    
    init(
        workoutDataService: WorkoutManagerProtocol
    ) {
        self.workoutDataService = workoutDataService
    }
    
    func getAllWorkouts(descending: Bool?) async throws {
        self.workouts = try await workoutDataService.getAllWorkouts(descending: descending)
    }
    
    func binding(for workoutId: String) -> Binding<DBWorkout>? {
        guard let index = workouts.firstIndex(where: {$0.id == workoutId }) else {
            return nil
        }
        
        return Binding(
            get: {self.workouts[index]},
            set: {self.workouts[index] = $0}
        )
    }
    
    func removeWorkout(workoutId: String) async throws {
        try await workoutDataService.removeWorkout(workoutId: workoutId)
    }
    
    func createWorkout(name: String, description: String, date: Date) async throws -> DBWorkout {
        let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
        let username = try await UserManager.shared.getUser(userId: authUser.uid).username
        let newWorkout = DBWorkout(
            id: UUID().uuidString,
            username: username,
            name: name,
            description: description,
            date: date
        )
        try await workoutDataService.createNewWorkout(workout: newWorkout)
        try await getAllWorkouts(descending: dateOption?.dateDescending)
        return newWorkout
    }
    
    func filterDateOption(option: DateOption) async throws {
        self.dateOption = option
        try await self.getAllWorkouts(descending: dateOption?.dateDescending)
    }
}
