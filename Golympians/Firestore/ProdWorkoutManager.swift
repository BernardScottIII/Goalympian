//
//  WorkoutManager.swift
//  Goalympians
//
//  Created by Bernard Scott on 4/3/25.
//

// Problems with Singletons
// 1. Singletons are global, which will lead to clutter and confusion. Gets even worse in a multi-threaded env.
// 2. Unable to customize the init() because the singleton is initialized at write-time, as opposed to ideally at runtime
// 3. Unable to switch service providers, meaning I can't test my code!

import Foundation
import FirebaseFirestore

struct DBWorkoutArray: Codable {
    let workouts: [DBWorkout]
    let total, skip, limit: Int
}

struct DBWorkout: Identifiable, Codable, Hashable {
    let id: String
    let username: String
    var name: String
    var description: String
    var date: Date
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.id, forKey: .id)
        try container.encode(self.username, forKey: .username)
        try container.encode(self.name, forKey: .name)
        try container.encode(self.description, forKey: .description)
        try container.encode(self.date, forKey: .date)
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case username = "username"
        case name = "name"
        case description = "description"
        case date = "date"
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.username = try container.decode(String.self, forKey: .username)
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decode(String.self, forKey: .description)
        self.date = try container.decode(Date.self, forKey: .date)
    }
    
    init(
        id: String,
        username: String,
        name: String,
        description: String,
        date: Date
    ) {
        self.id = id
        self.username = username
        self.name = name
        self.description = description
        self.date = date
    }
}

final class ProdWorkoutManager: WorkoutManagerProtocol {
    
    private var workoutCollection: CollectionReference //= Firestore.firestore().collection("workouts")
    
    init(workoutCollection: CollectionReference) {
        self.workoutCollection = workoutCollection
    }
    
    private func workoutDocument(workoutId: String) -> DocumentReference {
        workoutCollection.document(workoutId)
    }
    
    func createNewWorkout(workout: DBWorkout) async throws {
        try workoutDocument(workoutId: workout.id).setData(from: workout, merge: false)
    }
    
    func getWorkout(workoutId: String) async throws -> DBWorkout {
        try await workoutDocument(workoutId: workoutId).getDocument(as: DBWorkout.self)
    }
    
    func getAllWorkouts(descending: Bool?) async throws -> [DBWorkout] {
        let userId = try AuthenticationManager.shared.getAuthenticatedUser().uid
        let username = try await UserManager.shared.getUser(userId: userId).username
        
        var result: Query = workoutCollection
            .whereField(DBWorkout.CodingKeys.username.rawValue, isEqualTo: username)
        
        if let descending = descending {
            result = result.order(by: DBWorkout.CodingKeys.date.rawValue, descending: descending)
        }
        
        return try await result.getDocuments(as: DBWorkout.self)
    }
    
    func updateWorkout(workout: DBWorkout) async throws {
        try workoutDocument(workoutId: workout.id).setData(from: workout, merge: true)
    }
    
    func removeWorkout(workoutId: String) async throws {
        let activities = try await getAllWorkoutActivities(workoutId: workoutId)
        for activity in activities {
            try await removeWorkoutActivity(workoutId: workoutId, activityId: activity.id)
        }
        
        try await workoutDocument(workoutId: workoutId).delete()
    }
    
    func changeUsername(from oldUsername: String, to newUsername: String) async throws {
        var lastDoc: DocumentSnapshot? = nil
        while true {
            var query: Query = workoutCollection
                .whereField(DBWorkout.CodingKeys.username.rawValue, isEqualTo: oldUsername)
                .order(by: FieldPath.documentID()).limit(to: 300)
            if let last = lastDoc {
                query = query.start(afterDocument: last)
            }
            
            let snapshot = try await query.getDocuments()
            if snapshot.documents.isEmpty { break }
            
            let batch = Firestore.firestore().batch()
            
            for doc in snapshot.documents {
                var data = doc.data()
                
                if let oldUsername = data[DBWorkout.CodingKeys.username.rawValue] as? String {
                    data[DBWorkout.CodingKeys.username.rawValue] = newUsername
                }
                
                batch.setData(data, forDocument: doc.reference, merge: true)
            }
            
            try await batch.commit()
            lastDoc = snapshot.documents.last
        }
    }
}

// MARK: Workout Activity
extension ProdWorkoutManager {
    
    private func workoutActivityDocument(workoutId: String, activityId: String) -> DocumentReference {
        workoutActivityCollection(workoutId: workoutId).document(activityId)
    }
    
    private func workoutActivityCollection(workoutId: String) -> CollectionReference {
        workoutDocument(workoutId: workoutId).collection("activities")
    }
    
    func addWorkoutActivity(workoutId: String, exercise: APIExercise) async throws {
        let document = workoutActivityCollection(workoutId: workoutId).document()
        let documentId = document.documentID
        let exerciseCount = try await workoutActivityCollection(workoutId: workoutId).count.getAggregation(source: .server).count.intValue
        
        let initialSet: DBActivitySet
        switch exercise.setType {
        case .resistance:
            initialSet = .resistance(DBResistanceSet(id: UUID().uuidString, setIndex: 0, weight: 0.0 ,repetitions: 0))
        case .run:
            initialSet = .run(DBRunSet(id: UUID().uuidString, setIndex: 0, distance: 0.0, elevation: 0.0, duration: 0.0))
        case .swim:
            initialSet = .swim(DBSwimSet(id: UUID().uuidString, setIndex: 0, distance: 0.0, laps: 0, duration: 0.0))
        }
        
        let activity = DBActivity(
            id: documentId,
            exerciseId: exercise.id!,
            setType: exercise.setType,
            workoutIndex: exerciseCount,
            activitySets: [initialSet]
        )
        
        try document.setData(from: activity, merge: false)
    }
    
    func removeWorkoutActivity(workoutId: String, activityId: String) async throws {
        try await workoutActivityDocument(workoutId: workoutId, activityId: activityId).delete()
    }
    
    func getAllWorkoutActivities(workoutId: String) async throws -> [DBActivity] {
        try await workoutActivityCollection(workoutId: workoutId)
            .order(by: DBActivity.CodingKeys.workoutIndex.rawValue)
            .getDocuments(as: DBActivity.self)
    }
    
    func updateWorkoutActivity(workoutId: String, activity: DBActivity) async throws {
        try workoutActivityDocument(workoutId: workoutId, activityId: activity.id).setData(from: activity, merge: true)
    }
    
    func getWorkoutActivity(workoutId: String, activityId: String) async throws -> DBActivity {
        try await workoutActivityDocument(workoutId: workoutId, activityId: activityId).getDocument(as: DBActivity.self)
    }
    
    func addEmptyActivitySet(workoutId: String, activity: DBActivity) async throws {
        let setIndex = activity.activitySets.count
        var newSet: DBActivitySet
            
        switch activity.setType {
        case .resistance: newSet = .resistance(DBResistanceSet(id: UUID().uuidString, setIndex: setIndex, weight: 0.0, repetitions: 0))
        case .run: newSet = .run(DBRunSet(id: UUID().uuidString, setIndex: setIndex, distance: 0.0, elevation: 0.0, duration: 0.0))
        case .swim: newSet = .swim(DBSwimSet(id: UUID().uuidString, setIndex: setIndex, distance: 0.0, laps: 0, duration: 0.0))
        }
            
        try await addActivitySet(workoutId: workoutId, activityId: activity.id, set: newSet)
    }
    
    func addActivitySet(workoutId: String, activityId: String, set: DBActivitySet) async throws {
        var activity = try await getWorkoutActivity(workoutId: workoutId, activityId: activityId)
        activity.activitySets.append(set)
        try await updateWorkoutActivity(workoutId: workoutId, activity: activity)
    }
    
    func removeActivitySet(workoutId: String, activity: DBActivity, set: DBActivitySet) async throws {
//        var activity = try await getWorkoutActivity(workoutId: workoutId, activityId: activityId)
        var newActivity = activity
        newActivity.activitySets.removeAll { $0.id == set.id }
        try await updateWorkoutActivity(workoutId: workoutId, activity: newActivity)

        
//        let data: [String:Any] = [
//            DBActivity.CodingKeys.activitySets.rawValue : FieldValue.arrayRemove([set])
//        ]
//        
//        print("DATA:", data)
//        try await workoutActivityDocument(workoutId: workoutId, activityId: activityId).updateData(data)
    }
}
