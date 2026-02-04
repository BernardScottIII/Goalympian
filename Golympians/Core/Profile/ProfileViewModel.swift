//
//  ProfileViewModel.swift
//  Golympians
//
//  Created by Bernard Scott on 7/24/25.
//

import SwiftUI

@MainActor
final class ProfileViewModel: ObservableObject {
    
    @Published var myProfile: Profile? = nil
    @Published private(set) var isFollowing: Bool? = nil
    
    let workoutDataService: WorkoutManagerProtocol
    
    init(
        workoutDataService: WorkoutManagerProtocol
    ) {
        self.workoutDataService = workoutDataService
    }
    
    func loadMyProfile() async throws {
        let userId = try AuthenticationManager.shared.getAuthenticatedUser().uid
        let username = try await UserManager.shared.getUser(userId: userId).username
        if username == "" {
            throw Profile.ProfileError.missingUsername
        }
        self.myProfile = try await loadProfile(username: username)
    }
    
    func loadProfile(username: String) async throws -> Profile {
        try await ProfileManager.shared.getProfile(username: username)
    }
    
    func addFollower(_ followRecipient: Profile, followedBy followInitiater: Profile?) {
        Task {
            if let followInitiater = followInitiater {
                try await ProfileManager.shared.addFollower(followRecipient, followedBy: followInitiater)
                self.isFollowing = true
            }
        }
    }
    
    func removeFollower(_ followRecipient: Profile, notFollowedBy followInitiater: Profile?) {
        Task {
            if let followInitiater = followInitiater {
                try await ProfileManager.shared.removeFollower(followRecipient, notFollowedBy: followInitiater)
                self.isFollowing = false
            }
        }
    }
    
    func checkIsFollowing(for profile: Profile) {
        if let myUsername = myProfile?.username {
            self.isFollowing = profile.followers.contains(myUsername)
        } else {
            self.isFollowing = nil
        }
    }
    
    func getFollowerCount(for username: String) async throws -> Int {
        try await ProfileManager.shared.getProfile(username: username).followers.count
    }
    
    func getFollowingCount(for username: String) async throws -> Int {
        try await ProfileManager.shared.getProfile(username: username).following.count
    }
    
    func updateProfileData(data: [String:Any]) async throws {
        if let username = myProfile?.username {
            try await ProfileManager.shared.updateProfile(username: username, data: data)            
        }
    }
    
    func changeUsername(to newUsername: String) async throws {
        if let username = myProfile?.username {
            try await ProfileManager.shared.changeUsername(from: username, to: newUsername)
        }
    }
    
    func changeAllWorkoutsUsername(to newUsername: String) async throws {
        if let username = myProfile?.username {
            try await workoutDataService.changeUsername(from: username, to: newUsername)
        }
    }
}
