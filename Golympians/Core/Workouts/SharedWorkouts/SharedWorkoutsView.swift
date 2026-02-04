//
//  SharedWorkoutsView.swift
//  Golympian
//
//  Created by Bernard Scott on 6/19/25.
//

import SwiftUI

struct SharedWorkoutsView: View {
    private let sharedWorkouts:[DBWorkout] = [
        .init(id: UUID().uuidString, username: UUID().uuidString, name: "Example 1", description: "Description 1", date: .now),
        .init(id: UUID().uuidString, username: UUID().uuidString, name: "Example 2", description: "Description 2", date: .now),
        .init(id: UUID().uuidString, username: UUID().uuidString, name: "Example 3", description: "Description 3", date: .now),
        .init(id: UUID().uuidString, username: UUID().uuidString, name: "Example 4", description: "Description 4", date: .now),
        .init(id: UUID().uuidString, username: UUID().uuidString, name: "Example 5", description: "Description 5", date: .now),
        .init(id: UUID().uuidString, username: UUID().uuidString, name: "Example 6", description: "Description 6", date: .now),
    ]
    
    var body: some View {
        List {
            ForEach(sharedWorkouts, id: \.id) { workout in
                NavigationLink {
                    Text(workout.name)
                    Text(workout.description)
                } label: {
                    Text(workout.name)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        SharedWorkoutsView()
    }
}
