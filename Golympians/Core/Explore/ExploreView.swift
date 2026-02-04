//
//  ExploreView.swift
//  Golympians
//
//  Created by Bernard Scott on 7/24/25.
//

import SwiftUI
import FirebaseFirestore

struct ExploreView: View {
    @EnvironmentObject private var deepLinkManager: DeepLinkManager
    
    @StateObject private var viewModel = ExploreViewModel()
    @State private var searchText: String = ""
    
    let workoutDataService: WorkoutManagerProtocol
    
    init(
        workoutDataService: WorkoutManagerProtocol
    ) {
        self.workoutDataService = workoutDataService
    }
    
    var body: some View {
        List {
            if searchText.isEmpty {
                Text("Find your friends!")
            } else {
                ForEach(viewModel.profiles.filter {
                    searchText.isEmpty ? true : $0.username.localizedStandardContains(searchText)
                }, id: \.username) { profile in
                    NavigationLink(value: profile) {
                        ProfileSearchResultView(profile: profile)
                    }
                }
            }
        }
        .searchable(text: $searchText)
        .navigationDestination(for: Profile.self, destination: { profile in
            ProfileView(profile: profile, workoutDataService: workoutDataService)
        })
        .navigationDestination(isPresented: Binding<Bool>(
            get: { deepLinkManager.navigatedToProfile != nil },
            set: { _ in deepLinkManager.navigatedToProfile = nil }
        )) {
            if let profile = deepLinkManager.navigatedToProfile {
                ProfileView(profile: profile, workoutDataService: workoutDataService)
            }
        }
        .onAppear {
            Task {
                try await viewModel.getProfiles()
            }
        }
    }
}

#Preview {
    @Previewable let workoutDataService = ProdWorkoutManager(workoutCollection: Firestore.firestore().collection("workouts"))
    NavigationStack {
        ExploreView(workoutDataService: workoutDataService)
    }
}
