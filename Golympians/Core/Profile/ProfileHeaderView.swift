//
//  ProfileHeaderView.swift
//  Golympians
//
//  Created by Bernard Scott on 8/3/25.
//

import SwiftUI
import FirebaseFirestore

struct ProfileHeaderView: View {
    @Binding var followerCount: Int
    @Binding var followingCount: Int
    let profile: Profile
    let workoutDataService: WorkoutManagerProtocol
    
    var body: some View {
        HStack {
            if let urlString = profile.photoURL, let url = URL(string: urlString) {
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
            
            VStack(alignment: .leading) {
                Text(profile.username)
                    .font(.title)
                    .fontWeight(.bold)
                Text(profile.nickname ?? "")
                
                HStack {
                    NavigationLink(value: profile.followers) {
                        VStack {
                            Text("Followers")
                            Text("\(followerCount)")
                        }
                    }
                    
                    NavigationLink(value: profile.following) {
                        VStack {
                            Text("Following")
                            Text("\(followingCount)")
                        }
                    }
                }
                
                Spacer()
            }
            .frame(height: 108)
            .buttonStyle(.plain)
            
            Spacer()
        }
        .navigationDestination(for: [String].self) { resultList in
            ProfileListView(usernames: resultList, workoutDataService: workoutDataService)
        }
    }
}

#Preview {
    @Previewable let workoutDataService = ProdWorkoutManager(workoutCollection: Firestore.firestore().collection("workouts"))
    @Previewable @State var followerCount: Int = 1
    @Previewable @State var followingCount: Int = 2
    NavigationStack {
        ProfileHeaderView(followerCount: $followerCount, followingCount: $followingCount, profile: Profile(username: "MyUsername", nickname: "My Nickname", followers: ["Nard"], following: ["Nard", "MyMan"], publicWorkoutIds: ["1234", "5678"], photoURL: nil, photoPath: nil), workoutDataService: workoutDataService)
    }
}
