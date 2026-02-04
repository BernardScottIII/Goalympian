//
//  ActivitySetView.swift
//  Golympian
//
//  Created by Bernard Scott on 6/11/25.
//

import SwiftUI
import FirebaseFirestore

struct ActivitySetsView: View {
    
    @ObservedObject var viewModel: ActivityViewModel
    let workoutId: String
    @Binding var activity: DBActivity
    
    init(
        viewModel: ActivityViewModel,
        workoutId: String,
        activity: Binding<DBActivity>
    ) {
        self.viewModel = viewModel
        self.workoutId = workoutId
        self._activity = activity
    }
    
    var body: some View {
        let activityId = activity.id
        
        ForEach(activity.activitySets, id: \.id) { set in
            ActivitySetView(
                set: set,
                onCommit: {
                    viewModel.updateActivitySet(workoutId: workoutId, activityId: activityId, updatedSet: $0)
                },
                onDelete: {
                    viewModel.removeActivitySet(workoutId: workoutId, activity: activity, set: $0)
                }
            )
        }
    }
}

#Preview {
    @Previewable let dataService = ProdWorkoutManager(workoutCollection: Firestore.firestore().collection("workouts"))
    @Previewable @State var activity = DBActivity(
        id: "VZQJzIRor2Lpm3jd8xbL",
        exerciseId: "0FE5722A-7D35-4307-9B37-D85B7CEB29D9",
        setType: .resistance,
        workoutIndex: 1,
        activitySets: [
            .resistance(
                DBResistanceSet(
                    id: UUID().uuidString,
                    setIndex: 0,
                    weight: 135,
                    repetitions: 10
                )
            ),
            .resistance(
                DBResistanceSet(
                    id: UUID().uuidString,
                    setIndex: 1,
                    weight: 155,
                    repetitions: 8
                )
            )
        ]
    )
    List {
        ActivitySetsView(
            viewModel: ActivityViewModel(dataService: dataService),
            workoutId: "04B1B625-2862-4D97-A071-C80AB24CC16C",
            activity: $activity
        )
    }
}
