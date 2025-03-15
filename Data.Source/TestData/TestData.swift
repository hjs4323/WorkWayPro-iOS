//
//  TestData.swift
//  WorkwayVer2
//
//  Created by loyH on 7/12/24.
//

import Foundation
import SwiftUI

let Trainees = ["하종석1", "하종석2", "하종석3", "하종석4", "하종석5", "하종석6", ]

//let testMuscles: [Muscle] = [
//    Muscle(id: 21, name: "대둔근", isLeft: true, part: 4),
//    Muscle(id: 22, name: "대둔근", isLeft: false, part: 4),
//    Muscle(id: 23, name: "대퇴직근", isLeft: true, part: 4),
//    Muscle(id: 24, name: "대퇴직근", isLeft: false, part: 4),
//    Muscle(id: 25, name: "햄스트링", isLeft: true, part: 4),
//    Muscle(id: 26, name: "햄스트링", isLeft: false, part: 4),
//    Muscle(id: 27, name: "전경골근", isLeft: true, part: 4),
//    Muscle(id: 28, name: "전경골근", isLeft: false, part: 4),
//]
//
//
//let muscleImgNameMap: [Int: Image] = [
//    21: Image("ft_attach/maximus_gluteus"),
//    22: Image("ft_attach/maximus_gluteus"),
//    23: Image("ft_attach/rectus_femoris"),
//    24: Image("ft_attach/rectus_femoris"),
//    25: Image("ft_attach/biceps_femoris"),
//    26: Image("ft_attach/biceps_femoris"),
//    27: Image("ft_attach/tibialis_anterior"),
//    28: Image("ft_attach/tibialis_anterior")
//]


let testReportSt = ReportST(
    who: "aaa",
    time: 0, 
    dshTime: 0,
    value: ["C3": [0.1 , 0.4], "C7": [0.2, 0.25], "T4": [0.3, 0.35], "T8": [0.4, 0.45], "T12": [0.1, 0.14]],
    score: 80
)

let lastTestReportSt = ReportST(
    who: "aaa",
    time: 0,
    dshTime: 0,
    value: ["C3": [0.4 , 0.4], "C7": [0.2, 0.25], "T4": [0.3, 0.35], "T8": [0.4, 0.45], "T12": [0.1, 0.14]],
    score: 90
)


let testReportFt = ReportFTDTO(
    who: "01011111111",
    muscles: ftMuscles,
    time: Int(Date(timeIntervalSinceNow: -20000).timeIntervalSince1970),
    dashboardTime: Int(Date(timeIntervalSinceNow: -20100).timeIntervalSince1970),
    corrScore: 90,
//    musScores: [80, 20, 10, 30, 40, 90, 20, 100],
//    tensions: [20, 10, 30, 40, 90, 20, 100, 80],
    crRates: [210, 130, 240, 190, 120, 100, 180, 220]
)

let lastTestReportFt = ReportFTDTO(
    who: "01011111111",
    muscles: ftMuscles,
    time: Int(Date().timeIntervalSince1970),
    dashboardTime: Int(Date(timeIntervalSinceNow: -20000).timeIntervalSince1970),
    corrScore: 60,
//    musScores: [70, 20, 10, 30, 40, 90, 20, 100],
//    tensions: [10, 10, 30, 40, 90, 20, 100, 80],
    crRates: [110, 230, 140, 190, 120, 100, 80, 120]
)

let testRawData1: [Float] = Array(repeating: stride(from: 0.0, through: 200.0, by: 1.0).map { Float($0) }, count: 20).flatMap{ $0 }
let testRawData2: [Float] = Array(repeating: stride(from: 200.0, through: 0.0, by: -1.0).map { Float($0) }, count: 20).flatMap{ $0 }

let testRawDatas:[[Float]] = Array(repeating: [testRawData1, testRawData2], count: 4).flatMap{ $0 }

let testStValues: [String: [Float]] = ["C3": [0.1 , 0.15], "C7": [0.2, 0.25], "T4": [0.3, 0.35], "T8": [0.4, 0.45], "T12": [0.1, 0.14]]

let testStSingleValue: [Float] = [0.1, 0.15]

let testSTParams = [
    STParam(
        spineCode: "c3l",
        values: [0.135810112012192, 0.372533469714372, 0.548816821194719, 0.785540178896899, 0.460675145454545].map { Float($0) }
    ),
    STParam(
        spineCode: "c3r",
        values: [0.168726152352564, 0.369986162266199, 0.519860637733801, 0.721120647647436, 0.4449234].map { Float($0) }
    ),
    STParam(
        spineCode: "c7l",
        values: [0.356032023409101, 0.426382626506345, 0.478771373493655, 0.549121976590899, 0.452577].map { Float($0) }
    ),
    STParam(
        spineCode: "c7r",
        values: [0.299518292245411, 0.40436805744502, 0.482447669827707, 0.587297435027317, 0.443407863636364].map { Float($0) }
    ),
    STParam(
        spineCode: "t4l",
        values: [0.249241725511563, 0.417871585991509, 0.543447014008491, 0.712076874488437, 0.4806593].map { Float($0) }
    ),
    STParam(
        spineCode: "t4r",
        values: [0.291965339850108, 0.413333188895202, 0.503713502013889, 0.625081351058983, 0.458523345454545].map { Float($0) }
    ),
    STParam(
        spineCode: "t8l",
        values: [0.173419653878776, 0.345143948515383, 0.473023742393708, 0.644748037030315, 0.409083845454545].map { Float($0) }
    ),
    STParam(
        spineCode: "t8r",
        values: [0.182870833423946, 0.355166423162945, 0.483471649564327, 0.655767239303326, 0.419319036363636].map { Float($0) }
    ),
    STParam(
        spineCode: "t12l",
        values: [0.171202065712988, 0.373751985693799, 0.524587032488019, 0.72713695246883, 0.449169509090909].map { Float($0) }
    ),
    STParam(
        spineCode: "t12r",
        values: [0.26947365794335, 0.372990304234101, 0.450077168493171, 0.553593814783922, 0.411533736363636].map { Float($0) }
    )
]

let testFTParam = FTParam(
//    tensionBorder = :[30,50],
    crBorder: [
        21:[400,600],
        22: [400,600],
        23: [225,335],
        24: [300,450],
        25: [250,375],
        26: [250,375],
        27: [350,525],
        28: [150,225],
    ],
//    rawUpper = mapOf(
//        21: 1f,
//        22: 1f,
//        23: 1f,
//        24: 1f,
//        25: 1f,
//        26: 1f,
//        27: 1f,
//        28: 1f,
//    ),
    rawBorder: [
        21: 350,
        22: 350,
        23: 200,
        24: 250,
        25: 200,
        26: 200,
        27: 300,
        28: 100,
    ],
    wsBorder: [
        21:[450, 10000,675],
        22:[450, 10000,675],
        23:[250, 10000,375],
        24:[350, 10000,525],
        25:[300, 10000,450],
        26:[250, 10000,375],
        27:[300, 10000,450],
        28:[150, 10000,225],
    ]
)
private func getActivBor(exerciseId: Int) -> [Int: [Float]] {
    let map: [Int: [Int: [Float]]] = [
        0: [
            7: [124.6060, 204.3175, 400.0],
            8: [93.01243, 193.61119, 400.0],
            17: [113.1157, 189.7447, 400.0],
            18: [76.31567, 191.12755, 400.0],
            1: [25.98399, 99.80417, 400.0],
            2: [20.69887, 83.21132, 400.0],
            11: [57.70301, 129.13331, 400.0],
            12: [44.72877, 140.60586, 400.0],
        ],
        1: [
            7: [65.07926, 214.93771, 400.0],
            8: [47.46917, 203.76285, 400.0],
            17: [79.37614, 207.71342, 400.0],
            18: [79.87126, 182.69416, 400.0],
            5: [80.86383, 156.76234, 400.0],
            6: [43.43036, 164.07019, 400.0],
            21: [101.3377, 190.4329, 400.0],
            22: [106.1516, 266.1448, 400.0],
        ]
    ]

    return map[exerciseId]!
}
private func getRawBorder(exerciseId: Int) -> [Int: [Float]] {
    let map: [Int: [Int: [Float]]] = [
        0: [
            7: [52.41183, 182.57738],
            8: [48.19037, 168.92807],
            17: [58.74067, 172.15916],
            18: [62.1275, 201.9956],
            1: [24.1275, 201.9956],
            2: [27.32885, 133.41337],
            11: [37.79449, 149.68354],
            12: [44.91961, 159.12662],
        ],
        1: [
            7: [93.99889, 212.64937],
            8: [113.6163, 245.0554],
            17: [88.91771, 262.60295],
            18: [74.11692, 194.69678],
            5: [54.72419, 178.38951],
            6: [46.81258, 161.57751],
            21: [50.84038, 193.58534],
            22: [49.7715, 192.9379],
        ]
    ]

    return map[exerciseId]!
}
private let mainMaxBor = [80, 400].map({ Float($0) })
private let mainMeanBor = [50, 200, 500].map({ Float($0) })
let testETParams = Array(0..<2).map { it in
    ETParamDTO(
        exid: it,
        activBor: getActivBor(exerciseId: it),
        mainMaxBor: mainMaxBor,
        mainMeanBor: mainMeanBor,
        rawBor: getRawBorder(exerciseId: it)
    )
}

let testClip1 = Clip(macAddress: "1", muscleId: 7, battery: 3.0, hubIndex: 0, battAlerted: false)
let testClip2 = Clip(macAddress: "2", muscleId: 8, battery: 3.1, hubIndex: 1, battAlerted: false)
let testClip3 = Clip(macAddress: "3", muscleId: 3, battery: 3.36, hubIndex: 2, battAlerted: false)
let testClip4 = Clip(macAddress: "4", muscleId: 4, battery: 3.6, hubIndex: 3, battAlerted: false)
let testClip5 = Clip(macAddress: "5", muscleId: 5, battery: 3.9, hubIndex: 4, battAlerted: false)
let testClip6 = Clip(macAddress: "6", muscleId: 6, battery: 4, hubIndex: 5, battAlerted: false)

let testClip7 = Clip(macAddress: "7", muscleId: 100, battery: 4, hubIndex: 6, battAlerted: false)
let testClip8 = Clip(macAddress: "8", muscleId: 101, battery: 4, hubIndex: 7, battAlerted: false)

let testClips = [testClip1, testClip2, testClip3, testClip4, testClip5, testClip6, testClip7, testClip8]

let testHub = Hub(name: "테스트허브", battery: 3.8, battAlerted: false)


let testExercises: [ExerciseDTO] = [
    ExerciseDTO(
        exerciseId: 0,
        name: "벤치프레스",
        part: 0,
        mainMuscles: [1,2,17,18,7,8,11,12].compactMap { mid in muscleDictionary[mid] },
        subMuscles: [15, 16].compactMap { mid in muscleDictionary[mid] }, 
        dfWei: 40,
        fromRelax: false
    ),
//    ExerciseDTO(
//        exerciseId: 3,
//        name: "스쿼트",
//        part: 3,
//        mainMuscles: [21,22,23,24,25,26,27,28].compactMap { mid in muscleDictionary[mid] },
//        subMuscles: [27, 28].compactMap { mid in muscleDictionary[mid] }
//    ),
//    ExerciseDTO(
//        exerciseId: 2,
//        name: "데드리프트",
//        part: 1,
//        mainMuscles: [3, 4, 21, 22, 25, 26].compactMap { mid in muscleDictionary[mid] },
//        subMuscles: [27, 28].compactMap { mid in muscleDictionary[mid] }
//    ),
    ExerciseDTO(
        exerciseId: 1,
        name: "오버헤드 프레스",
        part: 2,
        mainMuscles: [7,8,5,6,17,18,21,22].compactMap { mid in muscleDictionary[mid] },
        subMuscles: [1, 2].compactMap { mid in muscleDictionary[mid] },
        dfWei: 40,
        fromRelax: true
    ),
]


let testReportET: ReportETDTO = ReportETDTO(
    reportId: "",
    who: "01012345678",
    exerciseId: 1,
    dashboardTime: Int(Date(timeIntervalSinceNow: -15000).timeIntervalSince1970),
    exerciseTime: 300,
    reportSets: [
        ReportETSetDTO(
            reportETId: "",
            reportId: "",
            who: "",
            time: Int(Date(timeIntervalSinceNow: -10000).timeIntervalSince1970),
            exTime: 120,
            weight: 30,
            repCount: 8,
            muscles: testExercises.first(where: { $0.exerciseId == 1 })!.mainMuscles,
            score: 80,
            activation: [50, 100, 150, 200, 250, 300, 350, 400],
            mainMean: 81,
            mainMax: 81
        ),
        ReportETSetDTO(
            reportETId: "",
            reportId: "",
            who: "",
            time: Int(Date(timeIntervalSinceNow: -10000).timeIntervalSince1970),
            exTime: 120,
            weight: 40,
            repCount: 8,
            muscles: testExercises.first(where: { $0.exerciseId == 1 })!.mainMuscles,
            score: 80,
            activation: [10,30,33,50,60,66,80,90],
            mainMean: 81,
            mainMax: 81
        )
    ]
)

let lastTestReportET: ReportETDTO = ReportETDTO(
    reportId: "",
    who: "01012345678",
    exerciseId: 0,
    dashboardTime: Int(Date(timeIntervalSinceNow: -15000).timeIntervalSince1970),
    exerciseTime: 300,
    reportSets: [
        ReportETSetDTO(
            reportETId: "",
            reportId: "",
            who: "",
            time: Int(Date(timeIntervalSinceNow: -10000).timeIntervalSince1970),
            exTime: 120,
            weight: 40,
            repCount: 8,
            muscles: testExercises.first(where: { $0.exerciseId == 0 })!.mainMuscles,
            score: 80,
            activation: [10,30,33,50,60,66,80,90],
            mainMean: 81,
            mainMax: 81
        ),
        ReportETSetDTO(
            reportETId: "",
            reportId: "",
            who: "",
            time: Int(Date(timeIntervalSinceNow: -10000).timeIntervalSince1970),
            exTime: 120,
            weight: 40,
            repCount: 8,
            muscles: testExercises.first(where: { $0.exerciseId == 0 })!.mainMuscles,
            score: 80,
            activation: [10,30,33,50,60,66,80,90],
            mainMean: 81,
            mainMax: 81
        )
    ]
)

let testReportETSet: ReportETSetDTO = ReportETSetDTO(
    reportETId: "",
    reportId: "",
    who: "",
    time: Int(Date(timeIntervalSinceNow: -10000).timeIntervalSince1970),
    exTime: 120,
    weight: 40,
    repCount: 8,
    muscles: ftMuscles,
    score: 80,
    activation: [10,30,33,50,60,66,80,90],
    mainMean: 81,
    mainMax: 81
)

let lastTestReportBT = ReportBTDTO(
    reportId: "",
    who: "01099999999",
    name: "측정 2",
    dashboardTime: Int(Date(timeIntervalSinceNow: -2200000000).timeIntervalSince1970),
    setTimes: [1,2],
    muscleName: ["1", "2", "3", "4", "5", "6", "7", "8"],
    exerciseTime: 50000,
    reportSets: [
        ReportBTSetDTO(
            reportBTId: "",
            reportId: "",
            who: "01099999999",
            time: Int(Date(timeIntervalSinceNow: -2000).timeIntervalSince1970),
            exerciseTime: 4000,
            weight: 100,
            count: 10,
            topRaw: [600, 100, 600, 100, 600, 100, 600, 100],
            lowRaw: [400, 200, 400, 200, 400, 200, 400, 200]
        ),
        ReportBTSetDTO(
            reportBTId: "",
            reportId: "",
            who: "01099999999",
            time: Int(Date(timeIntervalSinceNow: -4000).timeIntervalSince1970),
            exerciseTime: 4000,
            weight: 111,
            count: 10,
            topRaw: [123, 100, 232, 100, 600, 100, 600, 100],
            lowRaw: [234, 200, 234, 200, 400, 200, 400, 200]
        )
])

let lastTestReportBT2 = ReportBTDTO(
    reportId: "",
    who: "01099999999",
    name: "측정 2",
    dashboardTime: Int(Date(timeIntervalSinceNow: -20000).timeIntervalSince1970),
    setTimes: [
        Int(Date(timeIntervalSinceNow: -3000).timeIntervalSince1970),
        Int(Date(timeIntervalSinceNow: -4000).timeIntervalSince1970)
    ],
    muscleName: ["1", "2", "3", "4", "5", "6", "7", "8"],
    exerciseTime: 50000,
    reportSets: [
        ReportBTSetDTO(
            reportBTId: "",
            reportId: "",
            who: "01099999999",
            time: Int(Date(timeIntervalSinceNow: -3000).timeIntervalSince1970),
            exerciseTime: 4000,
            weight: 100,
            count: 10,
            topRaw: [600, 100, 600, 100, 600, 100, 600, 100],
            lowRaw: [400, 200, 400, 200, 400, 200, 400, 200]
        ),
        ReportBTSetDTO(
            reportBTId: "",
            reportId: "",
            who: "01099999999",
            time: Int(Date(timeIntervalSinceNow: -4000).timeIntervalSince1970),
            exerciseTime: 4000,
            weight: 111,
            count: 10,
            topRaw: [123, 100, 232, 100, 600, 100, 600, 100],
            lowRaw: [234, 200, 234, 200, 400, 200, 400, 200]
        )
])

let testReportBT = ReportBTDTO(
    reportId: "test1",
    who: "01099999999",
    name: "측정 1",
    dashboardTime: Int(Date(timeIntervalSinceNow: -20000000).timeIntervalSince1970),
    setTimes: [
        Int(Date(timeIntervalSinceNow: -1000).timeIntervalSince1970),
        Int(Date(timeIntervalSinceNow: -2000).timeIntervalSince1970)
    ],
    muscleName: ["1", "2", "3", "4", "5", "6"],
    exerciseTime: 50000,
    reportSets: [
        ReportBTSetDTO(
            reportBTId: "",
            reportId: "",
            who: "01099999999",
            time: Int(Date(timeIntervalSinceNow: -1000).timeIntervalSince1970),
            exerciseTime: 4000,
            weight: nil,
            count: nil,
            topRaw: [600, 100, 600, 100, 600, 100],
            lowRaw: [400, 200, 400, 200, 400, 200],
            rawData: testRawDatas
        ),
        ReportBTSetDTO(
            reportBTId: "",
            reportId: "",
            who: "01099999999",
            time: Int(Date(timeIntervalSinceNow: -2000).timeIntervalSince1970),
            exerciseTime: 4000,
            weight: 111,
            count: 10,
            topRaw: [123, 100, 232, 100, 600, 100],
            lowRaw: [234, 200, 234, 200, 400, 200],
            rawData: testRawDatas
        )
])

let testReportBT2 = ReportBTDTO(
    reportId: "test1",
    who: "01099999999",
    name: "측정 1",
    dashboardTime: Int(Date(timeIntervalSinceNow: -10000).timeIntervalSince1970),
    setTimes: [
        Int(Date(timeIntervalSinceNow: -1000).timeIntervalSince1970),
        Int(Date(timeIntervalSinceNow: -2000).timeIntervalSince1970)
    ],
    muscleName: ["1", "2", "3", "4", "5", "6"],
    exerciseTime: 50000,
    reportSets: [
        ReportBTSetDTO(
            reportBTId: "",
            reportId: "",
            who: "01099999999",
            time: Int(Date(timeIntervalSinceNow: -1000).timeIntervalSince1970),
            exerciseTime: 4000,
            weight: 100,
            count: 10,
            topRaw: [600, 100, 600, 100, 600, 100],
            lowRaw: [400, 200, 400, 200, 400, 200],
            rawData: testRawDatas
        ),
        ReportBTSetDTO(
            reportBTId: "",
            reportId: "",
            who: "01099999999",
            time: Int(Date(timeIntervalSinceNow: -2000).timeIntervalSince1970),
            exerciseTime: 4000,
            weight: 111,
            count: 10,
            topRaw: [123, 100, 232, 100, 600, 100],
            lowRaw: [234, 200, 234, 200, 400, 200],
            rawData: testRawDatas
        )
])

let testReportBTSet = ReportBTSetDTO(
    reportBTId: "test1",
    reportId: "",
    who: "01099999999",
    time: Int(Date(timeIntervalSinceNow: -1000).timeIntervalSince1970),
    exerciseTime: 4000,
    weight: 100,
    count: 10,
    topRaw: [600, 100, 600, 100, 600, 100, 600, 100],
    lowRaw: [400, 200, 400, 200, 400, 200, 400, 200],
    rawData: testRawDatas
)


let testReportBTArr = [testReportBT, testReportBT]

let testDashbaordET: DashboardETDTO = DashboardETDTO(averageScore: 80, totalWeight: 90, bestId: 0, bestScore: 90, worstId: 1, worstScore: 60)

let testDashboard1: DashboardDTO = DashboardDTO(
    who: "123",
    time: Int(Date().timeIntervalSince1970 - 100000000),
    totTime: 3600,
    st: true,
    ft: false,
    dashboardET: testDashbaordET,
    bt: true,
    reportSTs: [lastTestReportSt, testReportSt],
    reportFTs: [],
    reportETs: [lastTestReportET, testReportET],
    reportBTs: [lastTestReportBT, testReportBT]
)
let testDashboard2: DashboardDTO = DashboardDTO(
    who: "123",
    time: Int(Date().timeIntervalSince1970 - 500000),
    totTime: 3600,
    st: true,
    ft: true,
    dashboardET: DashboardETDTO(averageScore: 80, totalWeight: 1100, bestId: 0, bestScore: 99, worstId: 1, worstScore: 21),
    bt: true,
    reportSTs: [testReportSt],
    reportFTs: [testReportFt],
    reportETs: [testReportET],
    reportBTs: [lastTestReportBT2, testReportBT2]
)
let testDashboard3: DashboardDTO = DashboardDTO(
    who: "123",
    time: Int(Date().timeIntervalSince1970 - 1000),
    totTime: 3600,
    st: false,
    ft: true,
    dashboardET: testDashbaordET,
    bt: true,
    reportSTs: [],
    reportFTs: [lastTestReportFt, testReportFt],
    reportETs: [lastTestReportET, testReportET]
)

let testDashboards: [DashboardDTO] = [testDashboard1, testDashboard2, testDashboard3]

let testBTParam: BTParam = BTParam(maxBor: [1000, 500], meanBor: [400, 1000])

let testMuscleName: [String] = ["1번 근육", "2번 근육", "3번 근육", "4번 근육", "5번 근육", "6번 근육", "7번 근육", "8번 근육"]
