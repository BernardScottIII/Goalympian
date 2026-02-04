//
//  ProfileListView.swift
//  Golympians
//
//  Created by Bernard Scott on 8/4/25.
//

import SwiftUI
import FirebaseFirestore

struct ProfileListView: View {
    @StateObject private var viewModel = ProfileListViewModel()
    
    let usernames: [String]
    let workoutDataService: WorkoutManagerProtocol
    
    var body: some View {
        List {
            ForEach(viewModel.profiles, id: \.username) { profile in
                NavigationLink(value: profile) {
                    ProfileSearchResultView(profile: profile)
                }
            }
        }
        .onAppear {
            Task {
                try await viewModel.fetchProfiles(usernames: usernames)
            }
        }
        .navigationDestination(for: Profile.self, destination: { profile in
            ProfileView(profile: profile, workoutDataService: workoutDataService)
        })
    }
}

#Preview {
    @Previewable let workoutDataService = ProdWorkoutManager(workoutCollection: Firestore.firestore().collection("workout"))
    NavigationStack {
        ProfileListView(usernames: ["MyMan", "Nard"], workoutDataService: workoutDataService)
    }
}
