//
//  ActivityManager.swift
//  Goalympians
//
//  Created by Bernard Scott on 4/7/25.
//

import Foundation

enum DBActivitySet: Identifiable, Codable {
    case resistance(DBResistanceSet)
    case run(DBRunSet)
    case swim(DBSwimSet)

    enum Kind: String, Codable {
        case resistance, run, swim
    }

    var id: String {
        payload.id
    }

    var setIndex: Int {
        payload.setIndex
    }

    private var kind: Kind {
        switch self {
        case .resistance: return .resistance
        case .run: return .run
        case .swim: return .swim
        }
    }

    private var payload: any BaseSet {
        switch self {
        case .resistance(let s): return s
        case .run(let s): return s
        case .swim(let s): return s
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .type)

        switch kind {
        case .resistance:
            self = .resistance(try container.decode(DBResistanceSet.self, forKey: .data))
        case .run:
            self = .run(try container.decode(DBRunSet.self, forKey: .data))
        case .swim:
            self = .swim(try container.decode(DBSwimSet.self, forKey: .data))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(kind, forKey: .type)
        
        switch self {
        case .resistance(let s):
            try container.encode(s, forKey: .data)
        case .run(let s):
            try container.encode(s, forKey: .data)
        case .swim(let s):
            try container.encode(s, forKey: .data)
        }
    }

    enum CodingKeys: String, CodingKey {
        case type
        case data
    }
}

protocol BaseSet: Identifiable, Codable {
    var id: String { get }
    var setIndex: Int { get }
}

struct DBResistanceSet: Identifiable, BaseSet {
    let id: String
    let setIndex: Int
    let weight: Double
    let repetitions: Int
}

struct DBRunSet: Identifiable, BaseSet {
    let id: String
    let setIndex: Int
    let distance: Double
    let elevation: Double
    let duration: Double
}

struct DBSwimSet: Identifiable, BaseSet {
    let id: String
    let setIndex: Int
    let distance: Double
    let laps: Int
    let duration: Double
}

enum SetType: String, Codable, CaseIterable {
    case resistance = "resistance_set"
    case run = "run_set"
    case swim = "swim_set"

    var prettyString: String {
        switch self {
        case .resistance: return "Resistance Exercise"
        case .run: return "Walk/Jog/Run"
        case .swim: return "Swimming"
        }
    }
    
    var keys: [String] {
        switch self {
        case .resistance: return ["weight", "repetitions"]
        case .run: return ["distance", "elevation", "duration"]
        case .swim: return ["distance", "laps", "duration"]
        }
    }
    
    var keySymbols: [String:String] {
        switch self {
        case .resistance: return [ "weight": "scalemass.fill", "repetitions": "checkmark.arrow.trianglehead.counterclockwise" ]
        case .run: return [ "distance": "point.bottomleft.forward.to.arrow.triangle.scurvepath.fill", "elevation": "barometer", "duration": "stopwatch.fill" ]
        case .swim: return [ "distance": "point.bottomleft.forward.to.arrow.triangle.scurvepath.fill", "laps": "point.forward.to.point.capsulepath", "duration": "stopwatch.fill" ]
        }
    }
}

struct DBActivity: Identifiable, Codable {
    let id: String
    let exerciseId: String
    let setType: SetType
    let workoutIndex: Int
    var activitySets: [DBActivitySet]
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case exerciseId = "exercise_id"
        case setType = "set_type"
        case workoutIndex = "workout_index"
        case activitySets = "activity_sets"
    }
}

extension DBActivitySet {
    func withIndex(_ index: Int) -> DBActivitySet {
        switch self {
        case .resistance(let s):
            return .resistance(
                DBResistanceSet(
                    id: s.id,
                    setIndex: index,
                    weight: s.weight,
                    repetitions: s.repetitions
                )
            )
        case .run(let s):
            return .run(
                DBRunSet(
                    id: s.id,
                    setIndex: index,
                    distance: s.distance,
                    elevation: s.elevation,
                    duration: s.duration
                )
            )
        case .swim(let s):
            return .swim(
                DBSwimSet(
                    id: s.id,
                    setIndex: index,
                    distance: s.distance,
                    laps: s.laps,
                    duration: s.duration
                )
            )
        }
    }
}

