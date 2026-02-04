//
//  CompleteProfileView.swift
//  Golympians
//
//  Created by Bernard Scott on 7/22/25.
//

import SwiftUI
import PhotosUI

struct CompleteProfileView: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var username: String = ""
    @State private var nickname: String = ""
    @State private var age: Int = 0
    @State private var birthday: Date = Date.now
    @State private var weight: Double = 0.0
    @State private var selectedPhoto: PhotosPickerItem? = nil
    @State private var imageData: Data? = nil
    @State private var url: URL? = nil
    @State private var legacyMigrationAlert: Bool = false
    
    @StateObject private var userAccountViewModel = UserAccountViewModel()
    private let dateRange: ClosedRange<Date> = {
        let calendar = Calendar.current
        let startComponents = DateComponents(year: 1970, month: 1, day: 1)
        return calendar.date(from:startComponents)! ... Date(timeIntervalSinceNow: 0)
    }()
    
    @StateObject private var viewModel = CompleteProfileViewModel()

    @Binding var profileIncomplete: Bool
    
    var body: some View {
        ScrollView {
            HStack {
                Text("Update Notice")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            HStack {
                Text("""
If you are seeing this screen, thank you for being an early adopter! We've just added public profiles to Golympians, which means the app needs a little bit more info to work properly!
""")
                
                Spacer()
            }
            
            Spacer()
            
            Section("Profile Picture") {
                PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                    if let imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 108, height: 108)
                            .clipShape(.circle)
                    } else if let url {
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
                        ZStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 108))
                                .foregroundStyle(.gray.opacity(0.7))
                            Text("Tap to upload profile picture")
                                .frame(width: 96)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(colorScheme == .light ? .black : .white)
                        }
                    }
                }
                .onChange(of: selectedPhoto) { oldValue, newValue in
                    guard let newValue else { return }
                    Task {
                        // 1) Show image immediately
                        if let data = try? await newValue.loadTransferable(type: Data.self) {
                            await MainActor.run { imageData = data }
                        }

                        // 2) Continue your existing upload + user reload flow
                        do {
                            try await userAccountViewModel.saveFirstProfileImage(item: newValue)
                            try await userAccountViewModel.loadCurrentUserAndProfile()
                            if let photoURL = userAccountViewModel.user?.photoURL {
                                await MainActor.run { url = URL(string: photoURL) }
                            }
                        } catch {
                            // Handle errors (optionally reset imageData or show an alert)
                        }
                    }
                }
            }
            
            Spacer()
            
            Section {
                TextField("Your Username", text: $username)
                    .padding()
                    .background(Color.gray.opacity(0.4))
                    .clipShape(.buttonBorder)
                    .onChange(of: username) { oldValue, newValue in
                        if !newValue.isEmpty {
                            Task {
                                try await viewModel.checkUniqueness(username)
                                viewModel.checkFormCompletion()
                            }
                        }
                    }
            } header: {
                HStack {
                    Text("Username")
                        .font(.headline)
                    Spacer()
                }
            } footer: {
                if viewModel.usernameIsUnique && !username.isEmpty {
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
            
            Section {
                TextField("What do you like to go by?", text: $nickname)
                    .padding()
                    .background(Color.gray.opacity(0.4))
                    .clipShape(.buttonBorder)
            } header: {
                HStack {
                    Text("Nickname (Optional)")
                        .font(.headline)
                    Spacer()
                }
            } footer: {
                HStack {
                    Image(systemName: "info.circle")
                    // Magic number here. My intention is for the icon to be the same height as text
                        .font(.system(size: 24))
                    
                    Text("This name will be publicly displayed on your profile.")
                    
                    Spacer()
                }
                .foregroundStyle(.yellow)
                
            }
            
            Section {
                DatePicker("Birthday", selection: $birthday, in: dateRange, displayedComponents: [.date])
                    .padding()
                    .background(Color.gray.opacity(0.4))
                    .clipShape(.buttonBorder)
            } header: {
                HStack {
                    Text("Age (Optional)")
                        .font(.headline)
                    Spacer()
                }
            }
            
            Section {
                HStack {
                    TextField("How much do you weigh?", value: $weight, format: .number)
                        .padding()
                        .background(Color.gray.opacity(0.4))
                        .clipShape(.buttonBorder)
                        .keyboardType(.numberPad)
                    
                    Menu("Units") {
                        ForEach(MeasurementUnits.allCases, id: \.self) { metric in
                            Button {
                                viewModel.setMeasurementUnit(metric)
                            } label: {
                                if metric == viewModel.measurementUnitSelection {
                                    Image(systemName: "checkmark")
                                }
                                Text(metric.prettyString)
                            }
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Weight (Units: \(viewModel.measurementUnitDisplay)) (Optional)")
                        .font(.headline)
                    Spacer()
                }
            }
        }
        .padding()
        .onAppear {
            Task {
                try await userAccountViewModel.migrateLegacyUser()
                try await userAccountViewModel.loadCurrentUserAndProfile()
            }
        }
        .onChange(of: selectedPhoto, { oldValue, newValue in
            if let newValue {
                Task {
                    try await userAccountViewModel.saveFirstProfileImage(item: newValue)
                    try await userAccountViewModel.loadCurrentUserAndProfile()
                    if let photoURL = userAccountViewModel.user?.photoURL {
                        url = URL(string: photoURL)
                    }
                }
            }
        })
        
        Button {
            Task {
                let userId = userAccountViewModel.user!.userId
                
                let newProfile = Profile(
                    username: username,
                    nickname: nickname,
                    followers: [],
                    following: [],
                    publicWorkoutIds: [],
                    photoURL: userAccountViewModel.user?.photoURL,
                    photoPath: userAccountViewModel.user?.photoImagePath
                )
                try await viewModel.setUserData(userId: userId, data: ["username":username])
                
                try await viewModel.createNewProfile(profile: newProfile)
            }
            profileIncomplete.toggle()
        } label: {
            Text("Continue")
                
        }
        .disabled(viewModel.formIsIncomplete)
    }
}

#Preview {
    NavigationStack {
        CompleteProfileView(profileIncomplete: .constant(true))
    }
}
