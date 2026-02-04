//
//  ContentView.swift
//  AppDataTest
//
//  Created by Bernard Scott on 3/3/25.
//

import SwiftUI
import FirebaseFirestore

enum TabbarTab: Hashable {
    case workouts, insights, profile, explore
}

struct TabbarView: View {
    
    @EnvironmentObject private var deepLinkManager: DeepLinkManager
    
    @State private var workoutNavigationPath = NavigationPath()
    @State private var insightNavigationPath = NavigationPath()
    @State private var profileNavigationPath = NavigationPath()
    @State private var exploreNavigationPath = NavigationPath()
    
    @Binding var showSignInView: Bool
    @Binding var profileIncomplete: Bool
    let workoutDataService: WorkoutManagerProtocol
    
    init(
        workoutDataService: WorkoutManagerProtocol,
        showSignInView: Binding<Bool>,
        profileIncomplete: Binding<Bool>
    ) {
        _showSignInView = showSignInView
        _profileIncomplete = profileIncomplete
        self.workoutDataService = workoutDataService
    }
    
    var body: some View {
        TabView(selection: $deepLinkManager.selectedTab) {
            Tab("Workouts", systemImage: "dumbbell", value: .workouts) {
                NavigationStack(path: $workoutNavigationPath) {
//                    WorkoutsView(workoutDataService: workoutDataService)
                    UserWorkoutsView(workoutDataService: workoutDataService, path: $workoutNavigationPath)
                }
            }
            
            Tab("Insights", systemImage: "chart.xyaxis.line", value: .insights) {
                NavigationStack(path: $insightNavigationPath) {
                    InsightsView(showSignInView: $showSignInView)
                }
            }
            
            Tab("Explore", systemImage: "magnifyingglass", value: .explore) {
                NavigationStack(path: $exploreNavigationPath) {
                    ExploreView(workoutDataService: workoutDataService)
                }
            }
            
            Tab("Profile", systemImage: "person", value: .profile) {
                NavigationStack(path: $profileNavigationPath) {
                    UserAccountView(showSignInView: $showSignInView, profileIncomplete: $profileIncomplete, workoutDataService: workoutDataService)
                }
            }
        }
        .onChange(of: deepLinkManager.selectedTab) {
            if deepLinkManager.selectedTab == .workouts { workoutNavigationPath = NavigationPath() }
            if deepLinkManager.selectedTab == .insights { insightNavigationPath = NavigationPath() }
            if deepLinkManager.selectedTab == .profile { profileNavigationPath = NavigationPath() }
            if deepLinkManager.selectedTab == .explore { exploreNavigationPath = NavigationPath() }
        }
    }
}

#Preview {
    TabbarView(
        workoutDataService: ProdWorkoutManager(workoutCollection: Firestore.firestore().collection("workouts")),
        showSignInView: .constant(false), profileIncomplete: .constant(false)
    )
}

