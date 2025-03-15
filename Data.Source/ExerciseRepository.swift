//
//  ExerciseRepository.swift
//  WorkwayVer2
//
//  Created by 김성욱 on 8/21/24.
//

import Foundation


class ExerciseRepository{
    
    static let shared = ExerciseRepository()
    
    init() {
        Task {
            if self.muscles == nil {
                self.muscles = await getMuscles()
            }
            if self.exercises == nil {
                self.exercises = await getExercises()
            }
        }
    }
    
    private let fbStorage = FbStorage()
    private let fbStore = FbStore()
    var exercises: [ExerciseDTO]?
    var muscles: [MuscleDTO]?
    
    func getMuscles() async -> [MuscleDTO]? {
        print("ExerciseRepository/getMuscles: triggered")
        #if DEBUG // test
        return totalMuscles
        #endif
        do {
            let entities =  try await fbStore.getMuscles()
            let muscles =  entities.map({ MuscleDTO.fromEntity(entity: $0) })
            self.muscles = muscles
            print("ExerciseRepository/getMuscles: \(muscles.map({ $0.id }))")
            return muscles
        } catch {
            print("ExerciseRepository/getMuscles: error getting muscles \(error)")
            return nil
        }
    }
    
    func getExercises() async -> [ExerciseDTO]? {
        if muscles == nil {
            _ = await getMuscles()
        }
        print("ExerciseRepository/getExercises: triggered")
        #if DEBUG // test
        return testExercises
        #endif
        do {
            let entities = try await fbStore.getExercises()
            let exercises = entities.map({ ExerciseDTO.fromEntity(entity: $0, muscles: self.muscles!)})
            self.exercises = exercises
            print("ExerciseRepository/getExercises: \(exercises.map({ $0.exerciseId }))")
            return exercises
        } catch {
            print("ExerciseRepository/getExercises: error getting Exercises \(error)")
            return nil
        }
    }
    
    func getMusclesById(mid: Int) -> MuscleDTO? {
        guard let muscle = self.muscles?.first(where: { muscle in
            muscle.id == mid
        }) else {
            print("못 찾음")
            return nil
        }
        return muscle
    }
    
    func getExercisesById(exerciseId: Int) -> ExerciseDTO? {
        
        guard let exercise = self.exercises?.first(where: { exercise in
            exercise.exerciseId == exerciseId
        }) else {
            print("못 찾음")
            return nil
        }
        //        var localExercise = exercise
        //
        //        localExercise.imgRef = fbStorage.getImgRef(dir: FBStorageDirs.EXERCISE.rawValue, fileName: exercise.imgName)
        
        return exercise
    }
    
//    func getExercisesByIdAsync(exerciseId: Int) async -> Exercise? {
//        var exercise = await fbStore.getExerciseById(exerciseId: exerciseId)
//        print("exercise from firebase name = \(exercise?.name)")
//        if exercise == nil {
//            return nil
//        } else {
//            exercise!.imgRef = fbStorage.getImgRef(dir: FBStorageDirs.EXERCISE.rawValue, fileName: exercise!.imgName)
//            return exercise
//        }
//    }
}
