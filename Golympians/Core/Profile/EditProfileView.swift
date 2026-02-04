//
//  EditProfileView.swift
//  Golympians
//
//  Created by Bernard Scott on 8/5/25.
//

import SwiftUI
import PhotosUI
import FirebaseFirestore

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var nickname: String = ""
    @State private var savingProfile: Bool = false
    @State private var selectedPhoto: PhotosPickerItem? = nil
    
    @ObservedObject var profileViewModel: ProfileViewModel
    @ObservedObject var userAccountViewModel: UserAccountViewModel
    
    init(
        profileViewModel: ProfileViewModel,
        userAccountViewModel: UserAccountViewModel
    ) {
        self.profileViewModel = profileViewModel
        self.userAccountViewModel = userAccountViewModel
        if profileViewModel.myProfile?.nickname != nil {
            _nickname = State(initialValue: (profileViewModel.myProfile?.nickname)!)
        }
    }
    
    var body: some View {
        HStack {
            if let urlString = profileViewModel.myProfile?.photoURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 108, height: 108)
                        .clipShape(.circle)
                } placeholder: {
                    ProgressView()
                        .frame(width: 108, height: 108)
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 108))
            }
            
            Spacer()
            
            VStack {
                Spacer()
                
                PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                    Text("Change Image")
                }
                
                if userAccountViewModel.user?.photoImagePath != nil {
                    Spacer()
                    
                    Button("Delete Image") {
                        userAccountViewModel.deleteProfileImage()
                    }
                }
                
                Spacer()
            }
        }
        .frame(height: 120)
        .padding()
        
        List {
            Section("Information") {
                TextField("Nickname", text: $nickname)
            }
            
            NavigationLink {
                UpdateUsernameView(viewModel: profileViewModel)
            } label: {
                Button {} label: {
                    Text("Change Username")
                        .font(.headline)
                        .foregroundStyle(Color.white)
                        .frame(height: 55)
                        .frame(maxWidth: .infinity)
                        .background(Color.golympiansPrimary)
                        .clipShape(.buttonBorder)
                }
            }
            .listRowBackground(Color.golympiansPrimary)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
        }
        .navigationTitle("Edit Profile")
        .navigationBarBackButtonHidden()
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    if nickname != profileViewModel.myProfile?.nickname {
                        Task {
                            savingProfile = true
                            try await profileViewModel.updateProfileData(data: [
                                Profile.CodingKeys.nickname.rawValue: nickname
                            ])
                            savingProfile = false
                        }
                    }
                    dismiss()
                } label: {
                    Text("Save")
                }
            }
            
            ToolbarItem(placement: .topBarLeading) {
                Button("Discard") {
                    dismiss()
                    
                    // MARK: Known Issue
                    // If user updates their profile picture then presses "Discard",
                    // user will still have the new profile picture, when supposedly they're
                    // expecting to keep their old one
                }
            }
        }
        .fullScreenCover(isPresented: $savingProfile) {
            VStack {
                Text("Saving profile...")
                ProgressView()
            }
        }
        .onChange(of: selectedPhoto, { oldValue, newValue in
            if let newValue {
                userAccountViewModel.saveProfileImage(item: newValue)
            }
        })
    }
}

#Preview {
    @Previewable let workoutDataService = ProdWorkoutManager(workoutCollection: Firestore.firestore().collection("workouts"))
//    @Previewable @StateObject var profileVM = ProfileViewModel(workoutDataService: workoutDataService)
//    @Previewable @StateObject var userAccVM = UserAccountViewModel()
    NavigationStack {
        EditProfileView(profileViewModel: ProfileViewModel(workoutDataService: workoutDataService), userAccountViewModel: UserAccountViewModel())
    }
}
