//
//  CreateExercise.swift
//  AppDataTest
//
//  Created by Bernard Scott on 3/4/25.
//

import SwiftUI
import FirebaseFirestore

struct CreateExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var instructions: [String] = [""]
    @State private var numInstructions: Int = 1
    @State private var setType: SetType = SetType.resistance
    @State private var targetMuscle: MuscleOption = MuscleOption.allMuscles
    @State private var equipment: EquipmentOption = EquipmentOption.noEquipment
    @State private var customEquipment: String = ""
    @State private var instructionCountAlert: Bool = false
    @State private var duplicateExerciseAlert: Bool = false
    @State private var missingNameAlert: Bool = false
    @FocusState private var keyboardFocused: Bool
    @State private var showMuscleOptionSheet: Bool = false
    @State private var showEquipmentOptionSheet: Bool = false
    
    @ObservedObject var viewModel: ExercisesViewModel
    
    var body: some View {
        Form {
            Section("Information") {
                TextField("Exercise Name", text: $name)
                    .focused($keyboardFocused)
                    .textInputAutocapitalization(.words)
                
                Button("Primary Muscle: \(targetMuscle.prettyString)") {
                    showMuscleOptionSheet = true
                }
                .sheet(isPresented: $showMuscleOptionSheet) {
                    MuscleOptionMenuView(selection: $targetMuscle, isPresented: $showMuscleOptionSheet)
                }
                
                Button("Equipment Used: \(equipment.prettyString)") {
                    showEquipmentOptionSheet = true
                }
                .sheet(isPresented: $showEquipmentOptionSheet) {
                    EquipmentOptionMenuView(selection: $equipment, isPresented: $showEquipmentOptionSheet)
                }
                if (equipment == EquipmentOption.customEquipment) {
                    TextField("Custom Equipment Name", text: $customEquipment)
                        .textInputAutocapitalization(.words)
                }
            }
            
            Section {
                Picker("Type of Exercise", selection: $setType) {
                    ForEach(SetType.allCases, id: \.self) { set_type in
                        Text(set_type.prettyString)
                    }
                }
            } header: {
                Text("Exercise Type")
            } footer: {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                    // Magic number here. My intention is for the icon to be the same height as text
                        .font(.system(size: 24))
                    
                    Text("This cannot be changed once the exercise is created.")
                }
                .foregroundStyle(.red)
            }
            
            Section("Instructions") {
                HStack {
                    Text("Number of Instructions: \(numInstructions)")
                    Spacer()
                    Button("", systemImage: "plus") {
                        if numInstructions < 10 {
                            numInstructions += 1
                            instructions.append("")
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
                            instructions.removeLast()
                        }
                    }
                    
                }
                .buttonStyle(.plain)
                
                ForEach(0..<numInstructions, id:\.self) { step in
                    TextField("Step #\(step+1)", text: $instructions[step])
                        .textInputAutocapitalization(.sentences)
                }
            }
            
        }
        .scrollDismissesKeyboard(.immediately)
        .onAppear {
            Task {
                try await viewModel.getExercises()
                keyboardFocused = true
            }
        }
        .navigationTitle("Create Exercise")
        .alert(
            "Error Creating Exercise",
            isPresented: $missingNameAlert
        ) {
            Button("Okay", action: {})
        } message: {
            Text("Exercises must have a name to be saved. Please enter a unique name.")
        }
        .alert(
            "Error Creating Exercise",
            isPresented: $duplicateExerciseAlert
        ) {
            Button("Okay", action: {})
        } message: {
            Text("Exercise with this name already exists, try a new name.")
        }
        
        BottomActionButton(label: "Save New Exercise", action: saveExercise)
    }
    
    private func saveExercise() {
        var exerciseNames: [String] = []
        viewModel.exercises.forEach { exercise in
            exerciseNames.append(exercise.name)
        }
        
        duplicateExerciseAlert = exerciseNames.contains(name)
        missingNameAlert = name == ""
        
        if !duplicateExerciseAlert && !missingNameAlert {
            Task {
                try await viewModel.uploadExercise(
                    id: UUID().uuidString,
                    name: name,
                    equipment: equipment,
                    customEquipment: customEquipment,
                    target: targetMuscle,
                    secondaryMuscles: ["No secondary muscles"],
                    instructions: instructions,
                    gifUrl: "no url",
                    setType: setType
                )
                try await viewModel.getExercises()
            }
            dismiss()
        }
    }
}

#Preview {
    @Previewable let dataService = ProdWorkoutManager(workoutCollection: Firestore.firestore().collection("workouts"))
    NavigationStack {
        CreateExerciseView(viewModel: ExercisesViewModel(dataService: dataService))
    }
}
