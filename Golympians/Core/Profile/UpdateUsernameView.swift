//
//  UpdateUsernameView.swift
//  Golympians
//
//  Created by Bernard Scott on 8/5/25.
//

import SwiftUI
import FirebaseFirestore

struct UpdateUsernameView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showEmptyUsernameAlert: Bool = false
    @State private var savingProfile: Bool = false
    @StateObject private var completeProfileViewModel = CompleteProfileViewModel()

    @State private var newUsername: String
    
    @ObservedObject var viewModel: ProfileViewModel
    
    init(
        viewModel: ProfileViewModel
    ) {
        self.viewModel = viewModel
        if let profile = viewModel.myProfile {
            _newUsername = .init(wrappedValue: profile.username)
        } else {
            self.newUsername = ""
        }
    }
    
    var body: some View {
        
        VStack {
            HStack {
                Text("This is the page for updating a username.")
                Spacer()
            }
            .padding([.leading, .trailing])
            
            Form {
                Section {
                    TextField("New Username", text: $newUsername)
                        .padding()
                        .background(Color.gray.opacity(0.4))
                        .clipShape(.buttonBorder)
                        .onChange(of: newUsername) { oldValue, newValue in
                            if !newValue.isEmpty {
                                Task {
                                    try await completeProfileViewModel.checkUniqueness(newUsername)
                                    completeProfileViewModel.checkFormCompletion()
                                    print(completeProfileViewModel.usernameIsUnique)
                                }
                            }
                        }
                } footer: {
                    if completeProfileViewModel.usernameIsUnique && !newUsername.isEmpty {
                        HStack {
                            Image(systemName: "checkmark")
                            // Magic number here. My intention is for the icon to be the same height as text
                                .font(.system(size: 24))
                            
                            Text("This username is available")
                            
                            Spacer()
                        }
                        .foregroundStyle(.green)
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                            // Magic number here. My intention is for the icon to be the same height as text
                                .font(.system(size: 24))
                            
                            Text("This username has already been taken.")
                            
                            Spacer()
                        }
                        .foregroundStyle(.red)
                    }
                }
                .listRowInsets(EdgeInsets(.zero))
            }
            
            Spacer()
            
            BottomActionButton(label: "Update Username") {
                showEmptyUsernameAlert = newUsername.isEmpty || !completeProfileViewModel.usernameIsUnique
                
                if !showEmptyUsernameAlert {
                    Task {
                        savingProfile = true
                        try await viewModel.changeUsername(to: newUsername)
                        try await viewModel.changeAllWorkoutsUsername(to: newUsername)
                        try await viewModel.loadMyProfile()
                        savingProfile = false
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle("Update Username")
        .alert("Username in Use", isPresented: $showEmptyUsernameAlert) {
            Button("Okay", role: .cancel, action: {})
        } message: {
            Text("You cannot enter a username that is being used by another account.")
        }
        .fullScreenCover(isPresented: $savingProfile) {
            VStack {
                Text("Saving profile...")
                ProgressView()
            }
        }
    }
}

#Preview {
//    @Previewable let workoutDataService = 
    @Previewable @StateObject var viewModel = ProfileViewModel(workoutDataService: ProdWorkoutManager(workoutCollection: Firestore.firestore().collection("workouts")))
    NavigationStack {
        UpdateUsernameView(viewModel: viewModel)
    }
}
