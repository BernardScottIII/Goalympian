//
//  ProfileViewModel.swift
//  Goalympians
//
//  Created by Bernard Scott on 3/31/25.
//

import SwiftUI
import PhotosUI

@MainActor
final class UserAccountViewModel: ObservableObject {
    
    @Published private(set) var user: DBUser? = nil
    @Published private(set) var profile: Profile? = nil
    
    func loadCurrentUserAndProfile() async throws {
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        user = try await UserManager.shared.getUser(userId: authDataResult.uid)
        if let username = user?.username {
            profile = try await ProfileManager.shared.getProfile(username: username)
        }
    }
    
    func toggleDarkMode() {
        guard let user else { return }
        let currentValue = user.usingDarkMode ?? false
        Task {
            try await UserManager.shared.updateUserDarkMode(userId: user.userId, usingDarkMode: !currentValue)
            self.user = try await UserManager.shared.getUser(userId: user.userId)
        }
    }
    
    func saveFirstProfileImage(item: PhotosPickerItem) async throws {
        guard let user else { return }
        
        guard let data = try await item.loadTransferable(type: Data.self) else {
            return
        }
        let (path, _) = try await StorageManager.shared.saveImage(data: data)
        let url = try await StorageManager.shared.getURLForImage(path: path)
        try await UserManager.shared.updateUserProfileImagePath(userId: user.userId, path: path, url: url.absoluteString)
    }
    
    func saveProfileImage(item: PhotosPickerItem) {
        guard let user else { return }
        
        Task {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                return
            }
            let (path, _) = try await StorageManager.shared.saveImage(data: data)
            let url = try await StorageManager.shared.getURLForImage(path: path)
            try await UserManager.shared.updateUserProfileImagePath(userId: user.userId, path: path, url: url.absoluteString)
            try await ProfileManager.shared.updatePhotoURL(username: user.username, path: path, url: url.absoluteString)
        }
    }
    
    func deleteProfileImage() {
        guard let user, let path = user.photoImagePath else { return }
        
        Task {
            try await StorageManager.shared.deleteImage(path: path)
            try await UserManager.shared.updateUserProfileImagePath(userId: user.userId, path: nil, url: nil)
            try await ProfileManager.shared.updatePhotoURL(username: user.username, path: nil, url: nil)
        }
    }
    
    func migrateLegacyUser() async throws {
        print("started migration")
        let authDataResult = try AuthenticationManager.shared.getAuthenticatedUser()
        
        // this ideally should check if username is nil, but username can never be nil, and birthday is always filled in
        print("getting user")
        do {
            _ = try await UserManager.shared.getUser(userId: authDataResult.uid)
        } catch {
            let data = [
                DBUser.CodingKeys.photoURL.rawValue:"",
                DBUser.CodingKeys.photoImagePath.rawValue:"",
                DBUser.CodingKeys.birthday.rawValue:Date.now,
                DBUser.CodingKeys.username.rawValue:"",
                DBUser.CodingKeys.weight.rawValue:0.0,
                DBUser.CodingKeys.measurementUnit.rawValue:MeasurementUnits.imperial.rawValue
            ] as [String : Any]
            try await UserManager.shared.setUserData(userId: authDataResult.uid, data: data)
        }
    }
}
