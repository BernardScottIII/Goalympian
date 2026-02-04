//
//  WorkoutManagerProtocol.swift
//  Goalympians
//
//  Created by Bernard Scott on 4/21/25.
//

protocol WorkoutManagerProtocol {
    func createNewWorkout(workout: DBWorkout) async throws
    
    func getWorkout(workoutId: String) async throws -> DBWorkout
    
    func getAllWorkouts(descending: Bool?) async throws -> [DBWorkout]
    
    func updateWorkout(workout: DBWorkout) async throws
    
    func removeWorkout(workoutId: String) async throws
    
    func changeUsername(from oldUsername: String, to newUsername: String) async throws
    
    // MARK: WorkoutActivity Protocol
    func addWorkoutActivity(workoutId: String, exercise: APIExercise) async throws
    
    func removeWorkoutActivity(workoutId: String, activityId: String) async throws
    
    func getAllWorkoutActivities(workoutId: String) async throws -> [DBActivity]
    
    func updateWorkoutActivity(workoutId: String, activity: DBActivity) async throws
    
    func getWorkoutActivity(workoutId: String, activityId: String) async throws -> DBActivity
    
    func addEmptyActivitySet(workoutId: String, activity: DBActivity) async throws
    
    func addActivitySet(workoutId: String, activityId: String, set: DBActivitySet) async throws
    
    func removeActivitySet(workoutId: String, activity: DBActivity, set: DBActivitySet) async throws
}
