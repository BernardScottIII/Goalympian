//
//  ProfileSearchResultView.swift
//  Golympians
//
//  Created by Bernard Scott on 7/29/25.
//

import SwiftUI

struct ProfileSearchResultView: View {
    let profile: Profile
    
    var body: some View {
        HStack {
            if let urlString = profile.photoURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(.circle)
                } placeholder: {
                    ProgressView()
                        .frame(width: 48, height: 48)
                }
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 48))
            }
            
            VStack {
                Text(profile.username)
            }
        }
    }
}

#Preview {
    ProfileSearchResultView(profile: Profile(username: "Testing", nickname: nil, followers: [], following: [], publicWorkoutIds: [], photoURL: nil, photoPath: nil))
}
