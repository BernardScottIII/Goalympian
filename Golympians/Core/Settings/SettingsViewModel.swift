//
//  SettingsViewModel.swift
//  Goalympians
//
//  Created by Bernard Scott on 3/30/25.
//

import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    
    @Published var authProviders: [AuthProviderOption] = []
    @Published var authUser: AuthDataResultModel? = nil
    
    let workoutDataService: WorkoutManagerProtocol
    
    init(
        workoutDataService: WorkoutManagerProtocol
    ) {
        self.workoutDataService = workoutDataService
    }
    
    func loadAuthProviders() {
        if let providers = try? AuthenticationManager.shared.getProviders() {
            authProviders = providers
        }
    }
    
    func signOut() throws {
        try AuthenticationManager.shared.signOut()
    }
    
    func resetPassword() async throws {
        let authUser = try AuthenticationManager.shared.getAuthenticatedUser()
        guard let email = authUser.email else {
            throw URLError(.fileDoesNotExist)
        }
        try await AuthenticationManager.shared.resetPassword(email: email)
    }
    
    // MARK: Update these and add tests
    func updateEmail() async throws {
        let email = "hello123@gmail.com"
        try await AuthenticationManager.shared.updateEmail(email: email)
    }
    
    func updatePassword() async throws {
        let password = "password123"
        try await AuthenticationManager.shared.updatePassword(password: password)
    }
    
    func loadAuthUser() {
        self.authUser = try? AuthenticationManager.shared.getAuthenticatedUser()
    }
    
    func linkGoogleAccount() async throws {
        let helper = SignInGoogleHelper()
        let tokens = try await helper.signIn()
        self.authUser = try await AuthenticationManager.shared.linkGoogle(tokens: tokens)
        
    }
    
    func linkEmailAccount() async throws {
        let email = "hello123@gmail.com"
        let password = "Hello123!"
        self.authUser = try await AuthenticationManager.shared.linkEmail(email: email, password: password)
    }
}

// MARK: Account and Data Deletion
extension SettingsViewModel {
    func deleteAccount() async throws {
        let userId = try AuthenticationManager.shared.getAuthenticatedUser().uid
        let username = try await UserManager.shared.getUser(userId: userId).username
        
        // MARK: Exercise Removal
        let exercises = try await ExerciseManager.shared.getAllExercises(
            nameDescending: nil,
            forMuscle: nil,
            usingEquipment: nil,
            usernames: [username]
        )
        for exercise in exercises {
            try await ExerciseManager.shared.removeUserExercise(username: username, exercise: exercise)
        }
        
        // MARK: Workout Removal
        let workouts = try await workoutDataService.getAllWorkouts(descending: nil)
        for workout in workouts {
            try await workoutDataService.removeWorkout(workoutId: workout.id)
        }
        
        // MARK: Insight Removal
        let insights = try await UserManager.shared.getAllUserInsights(userId: userId)
        for insight in insights {
            try await UserManager.shared.deleteUserInsight(userId: userId, insightId: insight.id)
        }
        
        try await UserManager.shared.deleteUser(userId: userId)
        try await AuthenticationManager.shared.delete()
    }
}
