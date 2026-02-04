//
//  EditExerciseView.swift
//  Golympians
//
//  Created by Bernard Scott on 7/14/25.
//

import SwiftUI
import FirebaseFirestore

struct EditExerciseView: View {
    
    @Environment(\.dismiss) private var dismiss
    @State private var instructionCountAlert: Bool = false
    @State private var showMuscleOptionSheet: Bool = false
    @State private var showEquipmentOptionSheet: Bool = false
    
    @State private var equipment: EquipmentOption
    @State private var customEquipment: String
    @State private var numInstructions: Int
    
    @Binding var exercise: APIExercise
    @ObservedObject var viewModel: ExercisesViewModel
    
    init(
        exercise: Binding<APIExercise>,
        viewModel: ExercisesViewModel
    ) {
        _exercise = exercise
        self.viewModel = viewModel
        numInstructions = exercise.instructions.count
        
        if let initEquipment = EquipmentOption(rawValue: exercise.wrappedValue.equipment) {
            _equipment = State(initialValue: initEquipment)
            customEquipment = ""
        } else {
            _equipment = State(initialValue: EquipmentOption.customEquipment)
            customEquipment = exercise.wrappedValue.equipment
        }
    }
    
    var body: some View {
        Form {
            TextField("Exercise Name", text: $exercise.name)
            
            Button("Primary Muscle: \(exercise.target.prettyString)") {
                showMuscleOptionSheet = true
            }
            .sheet(isPresented: $showMuscleOptionSheet) {
                MuscleOptionMenuView(selection: $exercise.target, isPresented: $showMuscleOptionSheet)
            }
            
            Button("Equipment Used: \(equipment.prettyString)") {
                showEquipmentOptionSheet = true
            }
            .sheet(isPresented: $showEquipmentOptionSheet) {
                EquipmentOptionMenuView(selection: $equipment, isPresented: $showEquipmentOptionSheet)
            }
            
            if (equipment.rawValue == EquipmentOption.customEquipment.rawValue) {
                TextField("Custom Equipment Name", text: $customEquipment)
                    .textInputAutocapitalization(.words)
            }
            
            Section("Instructions") {
                HStack {
                    Text("Number of Instructions: \(numInstructions)")
                    Spacer()
                    Button("", systemImage: "plus") {
                        if numInstructions < 10 {
                            numInstructions += 1
                            exercise.instructions.append("")
                        } else {
                            instructionCountAlert = true
                        }
                    }
                    .alert(
                        "Too Many Instructions",
                        isPresented: $instructionCountAlert
                    ) {
                        Button("Okay", action: {})
                    } message: {
                        Text("Exercises can have a maximum of ten instructions.")
                    }
                    
                    Button("", systemImage: "minus") {
                        if (numInstructions > 1 ) {
                            numInstructions -= 1
                            exercise.instructions.removeLast()
                        }
                    }
                    
                }
                .buttonStyle(.plain)
                
                ForEach(0..<numInstructions, id:\.self) { step in
                    TextField("Step #\(step+1)", text: $exercise.instructions[step])
                        .textInputAutocapitalization(.sentences)
                }
            }
        }
        .navigationTitle("Edit Exercise")
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Save", action: saveExercise)
            }
        }
    }
    
    private func saveExercise() {
        Task {
            let savedEquipment = equipment != EquipmentOption.customEquipment ? equipment.rawValue : customEquipment
            exercise.equipment = savedEquipment
            
            try await viewModel.updateExercise(exercise: exercise)
            dismiss()
        }
    }
}

#Preview {
    @Previewable @State var exercise = APIExercise(name: "", equipment: "", target: .abductor, secondaryMuscles: [], instructions: [], gifUrl: "", username: "", setType: .resistance)
    @Previewable @StateObject var viewModel = ExercisesViewModel(dataService: ProdWorkoutManager(workoutCollection: Firestore.firestore().collection("workouts")))
    NavigationStack {
        EditExerciseView(exercise: $exercise, viewModel: viewModel)
    }
}
