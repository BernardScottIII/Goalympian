//
//  ProfileManager.swift
//  Golympians
//
//  Created by Bernard Scott on 7/23/25.
//

import Foundation
import FirebaseFirestore

struct Profile: Codable, Hashable {
    let username: String // Firestore Document ID
    var nickname: String?
    var followers: [String]
    var following: [String]
    var publicWorkoutIds: [String]
    var photoURL: String?
    var photoPath: String?
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.username, forKey: .username)
        try container.encodeIfPresent(self.nickname, forKey: .nickname)
        try container.encode(self.followers, forKey: .followers)
        try container.encode(self.following, forKey: .following)
        try container.encode(self.publicWorkoutIds, forKey: .publicWorkoutIds)
        try container.encode(self.photoURL, forKey: .photoURL)
        try container.encode(self.photoPath, forKey: .photoPath)
    }
    
    enum CodingKeys: String, CodingKey {
        case username = "username"
        case nickname = "nickname"
        case followers = "followers"
        case following = "following"
        case publicWorkoutIds = "public_workout_ids"
        case photoURL = "photo_url"
        case photoPath = "photo_path"
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.username = try container.decode(String.self, forKey: .username)
        self.nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
        self.followers = try container.decode([String].self, forKey: .followers)
        self.following = try container.decode([String].self, forKey: .following)
        self.publicWorkoutIds = try container.decode([String].self, forKey: .publicWorkoutIds)
        self.photoURL = try container.decodeIfPresent(String.self, forKey: .photoURL)
        self.photoPath = try container.decodeIfPresent(String.self, forKey: .photoPath)
    }
    
    init(
        username: String,
        nickname: String?,
        followers: [String],
        following: [String],
        publicWorkoutIds: [String],
        photoURL: String?,
        photoPath: String?
    ) {
        self.username = username
        self.nickname = nickname
        self.followers = followers
        self.following = following
        self.publicWorkoutIds = publicWorkoutIds
        self.photoURL = photoURL
        self.photoPath = photoPath
    }
    
    enum ProfileError: Error {
        case missingUsername
        case notAuthenticated
        case invalidState(String)
    }
}

final class ProfileManager {
    static let shared = ProfileManager()
    
    private init() {}
    private let profileCollection = Firestore.firestore().collection("profiles")
    
    private func profileDocument(username: String) -> DocumentReference {
        profileCollection.document(username)
    }
    
    func createNewProfile(profile: Profile) async throws {
        try profileDocument(username: profile.username).setData(from: profile, merge: false)
    }
    
    func getProfile(username: String) async throws -> Profile {
        try await profileDocument(username: username).getDocument(as: Profile.self)
    }
    
    func profileExists(username: String) async throws -> Bool {
        let profile = try? await getProfile(username: username)
        return profile == nil
    }
    
    func getAllProfiles() async throws -> [Profile] {
        try await profileCollection.getDocuments(as: Profile.self)
    }
    
    private func deleteProfile(profile: Profile) async throws {
        try await profileDocument(username: profile.username).delete()
    }
    
    func addFollower(_ followRecipient: Profile, followedBy followInitiater: Profile) async throws {
        let recipientData: [String: Any] = [
            Profile.CodingKeys.followers.rawValue: FieldValue.arrayUnion([followInitiater.username])
        ]
        
        let initiaterData: [String: Any] = [
            Profile.CodingKeys.following.rawValue: FieldValue.arrayUnion([followRecipient.username])
        ]
        
        try await profileDocument(username: followRecipient.username).updateData(recipientData)
        try await profileDocument(username: followInitiater.username).updateData(initiaterData)
    }
    
    func removeFollower(_ followRecipient: Profile, notFollowedBy followInitiater: Profile) async throws {
        let recipientData: [String: Any] = [
            Profile.CodingKeys.followers.rawValue: FieldValue.arrayRemove([followInitiater.username])
        ]
        
        let initiaterData: [String: Any] = [
            Profile.CodingKeys.following.rawValue: FieldValue.arrayRemove([followRecipient.username])
        ]
        
        try await profileDocument(username: followRecipient.username).updateData(recipientData)
        try await profileDocument(username: followInitiater.username).updateData(initiaterData)
    }
    
    func updatePhotoURL(username: String, path: String?, url: String?) async throws {
        let data: [String: Any] = [
            Profile.CodingKeys.photoURL.rawValue: url,
            Profile.CodingKeys.photoPath.rawValue: path
        ]
        
        try await profileDocument(username: username).updateData(data)
    }
    
    func queryProfiles(searchText: String) async throws -> [Profile] {
        try await profileCollection
            .whereField("username", isLessThanOrEqualTo: searchText)
            .whereField("username", isGreaterThanOrEqualTo: searchText)
//            .whereField("username", isEqualTo: searchText)
            .getDocuments(as: Profile.self)
    }
    
    func updateProfile(username: String, data: [String:Any]) async throws {
        try await profileDocument(username: username).updateData(data)
    }
    
    func changeUsername(from currUsername: String, to newUsername: String) async throws {
        // Update Original Profile
        let oldProfile = try await profileDocument(username: currUsername).getDocument(as: Profile.self)
        let newProfile = Profile(
            username: newUsername,
            nickname: oldProfile.nickname,
            followers: oldProfile.followers,
            following: oldProfile.following,
            publicWorkoutIds: oldProfile.publicWorkoutIds,
            photoURL: oldProfile.photoURL,
            photoPath: oldProfile.photoPath
        )
        try await createNewProfile(profile: newProfile)
        
        let userId = try AuthenticationManager.shared.getAuthenticatedUser().uid
        try await UserManager.shared.setUserData(userId: userId, data: [
            DBUser.CodingKeys.username.rawValue:newUsername
        ])
        
        // Update original profile's followers
        for follower in newProfile.followers {
            let followerProfile = try await getProfile(username: follower)
            try await addFollower(newProfile, followedBy: followerProfile)
            try await removeFollower(followerProfile, notFollowedBy: oldProfile)
        }
        
        // Update original profile's following
        for recipient in newProfile.following {
            let recipientPRofile = try await getProfile(username: recipient)
            try await addFollower(recipientPRofile, followedBy: newProfile)
            try await removeFollower(recipientPRofile, notFollowedBy: oldProfile)
        }
        
        try await deleteProfile(profile: oldProfile)
    }
}
