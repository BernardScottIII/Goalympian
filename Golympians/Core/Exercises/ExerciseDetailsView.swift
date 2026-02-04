//
//  ExerciseDetailsView.swift
//  Goalympians
//
//  Created by Bernard Scott on 4/5/25.
//

import SwiftUI
import FirebaseFirestore

struct ExerciseDetailsView: View {
    
    @State private var showMuscleOptionSheet: Bool = false
    
    @ObservedObject var viewModel: ExercisesViewModel
    @Binding var exercise: APIExercise
    
    var body: some View {
        HStack{
            Text(exercise.name)
                .font(.title)
                .fontWeight(.bold)
        }
        .padding()
        
        List {
            Section("Instructions") {
                ForEach(exercise.instructions, id: \.self) { instruction in
                    Text(instruction)
                }
            }
            Section("Equipment") {
                if let equipmentValue = EquipmentOption(rawValue: exercise.equipment) {
                    Text(equipmentValue.prettyString)
                } else {
                    Text(exercise.equipment)
                }
            }
            Section("Target Muscle") {
                Text(exercise.target.prettyString)
            }
            Section("Secondary Muscles") {
                ForEach(exercise.secondaryMuscles, id: \.self) { muscle in
                    Text(muscle)
                }
            }
        }
        .toolbar {
            ToolbarItem {
                NavigationLink("Edit") {
                    EditExerciseView(exercise: $exercise, viewModel: viewModel)
                }
            }
        }
    }
}

#Preview {
    @Previewable @StateObject var viewModel = ExercisesViewModel(dataService: ProdWorkoutManager(workoutCollection: Firestore.firestore().collection("workouts")))
    @Previewable @State var exercise = APIExercise(
        id: UUID().uuidString,
        name: "Sample Exercise",
        equipment: "Keyboard and Mouse",
        target: .allMuscles,
        secondaryMuscles: ["Forehead", "Fingers", "eyes"],
        instructions: ["Sit down at keyboard", "start typing", "nothing works", "cry"],
        gifUrl: "google.com",
        username: "SampleUsername",
        setType: .resistance
    )
    NavigationStack {
        NavigationLink("Exercise Details View") {
            ExerciseDetailsView(
                viewModel: viewModel,
                exercise: $exercise
            )
        }
    }
}
