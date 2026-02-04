//
//  ProfileView.swift
//  Goalympians
//
//  Created by Bernard Scott on 3/30/25.
//

import SwiftUI
import PhotosUI
import FirebaseFirestore

struct UserAccountView: View {
    @StateObject private var viewModel = UserAccountViewModel()
    @StateObject private var profileViewModel: ProfileViewModel
    //    @State private var userId: String = ""
    //    @State var profile: Profile? = nil
    @State private var followerCount: Int = 0
    @State private var followingCount: Int = 0
    
    @Binding var showSignInView: Bool
    @Binding var profileIncomplete: Bool
    let workoutDataService: WorkoutManagerProtocol
    
    init(
        showSignInView: Binding<Bool>,
        profileIncomplete: Binding<Bool>,
        workoutDataService: WorkoutManagerProtocol
    ) {
        self.workoutDataService = workoutDataService
        self._showSignInView = showSignInView
        self._profileIncomplete = profileIncomplete
        self._profileViewModel = StateObject(wrappedValue: ProfileViewModel(workoutDataService: workoutDataService))
    }
    
    var body: some View {
        if let profile = viewModel.profile {
            ProfileHeaderView(
                followerCount: $followerCount,
                followingCount: $followingCount,
                profile: profile,
                workoutDataService: workoutDataService
            )
            .padding()
            
            List {
                Section("Personal Content") {
                    NavigationLink("My Exercises") {
                        UserExerciseListView(
                            viewModel: ExercisesViewModel(dataService: workoutDataService),
                            username: profile.username,
                            workoutDataService: workoutDataService
                        )
                    }
                }
            }
            .scrollDisabled(true)
            .task {
                try? await viewModel.loadCurrentUserAndProfile()
                do {
                    try await profileViewModel.loadMyProfile()
                } catch {
                    profileIncomplete = true
                }
                if let profile = profileViewModel.myProfile {
                    followerCount = profile.followers.count
                    followingCount = profile.following.count
                }
            }
        }
        
        // MARK: Poor Coding Practice
        Text("")
        .onAppear {
            Task {
                try await viewModel.loadCurrentUserAndProfile()
            }
        }
        .onChange(of: showSignInView, { oldValue, newValue in
            Task {
                try await viewModel.loadCurrentUserAndProfile()
            }
        })
        .onChange(of: profileIncomplete) {
            if profileIncomplete == false {
                Task {
                    try await profileViewModel.loadMyProfile()
                    if let profile = profileViewModel.myProfile {
                        followerCount = profile.followers.count
                        followingCount = profile.following.count
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView(showSignInView: $showSignInView, workoutDataService: workoutDataService)
                } label: {
                    Image(systemName: "gear")
                        .font(.headline)
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                NavigationLink {
                    EditProfileView(profileViewModel: profileViewModel, userAccountViewModel: viewModel)
                } label: {
                    Text("Edit Profile")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        UserAccountView(
            showSignInView: .constant(false),
            profileIncomplete: .constant(false),
            workoutDataService: ProdWorkoutManager(workoutCollection: Firestore.firestore().collection("workouts"))
        )
    }
}
