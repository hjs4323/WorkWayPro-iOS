//
//  BluetoothViewModel.swift
//  WorkwayVer2
//
//  Created by 김성욱 on 7/11/24.
//

import Foundation
import CoreBluetooth
import SwiftUI

private let logicURL = "https://workway-datalogic-hnymha6oka-du.a.run.app"

extension BluetoothManager: ObservableObject {
    
    func setClips(clips: [Clip]) {
        self.clips = clips
        print("BlueoothViewModel/setClips: \(clips.map { $0.hubIndex })번 모듈 붙음")
    }
    func clipBattAlerted() {
        for i in clips.indices {
            clips[i].setBattAlerted()
        }
    }
    
    func removeClip(clip: Clip? = nil, getTemp: Bool = true){
        print("BluetoothViewModel/removeClip: clip = \(clip), getTemp = \(getTemp)")
        if let clip {
            changeLedStatus(clip, status: .blue)
            if let index = self.clips.firstIndex(of: clip) {
                self.clips.remove(at: index)
            }
        }
        else {
            if let clip = self.clips.last {
                if getTemp {
                    self.tempClip = clip
                    changeLedStatus(self.tempClip!, status: .whiteBlink)
                }
                else {
                    changeLedStatus(clip, status: .blue)
                }
                self.clips.removeLast()
            }
        }
    }
    
    func addClip(_ clip: Clip? = nil) {
            if let clip = clip {
                self.clips.append(clip)
                changeLedStatus(clip, status: .white)
            }
            else if let tempClip = tempClip {
                self.tempClip = nil
                self.clips.append(tempClip)
                changeLedStatus(tempClip, status: .white)
            }
    }
    
    func requestMissingData(_ packetNum: Int) {
        sendCommandToDevice(command: 0x55, payload: packetNum)
    }
    
    func requestNameChange(newName: String) {
        var asciiNameStr = ""
        newName.forEach { char in
            if let ascii = char.asciiValue {
                asciiNameStr += String(ascii)
            }
        }
        sendCommandToDevice(command: 0x60, hexString: asciiNameStr)
    }
    
    func requestConnectionInfo() {
        sendCommandToDevice(command: 0x61, payload: 0x00)
    }
    
    func deleteAllConnection() {
        sendCommandToDevice(command: 0x62, payload: 0x00)
    }
    
    ///slotNum을 0x00의 형태로 전송
    func deleteSpecificConnection(_ slotNum: Int) {
        sendCommandToDevice(command: 0x63, payload: slotNum)
    }
    
    func powerOffHub() {
        sendCommandToDevice(command: 0x64, payload: 0x00)
    }
    
    func powerOffClip(_ clips: [Clip]) {
        clips.forEach { clip in
            sendCommandToDevice(command: 0x65, hexString: clip.macAddress)
            if let index = self.clips.firstIndex(of: clip) {
                self.clips.remove(at: index)
            }
        }
    }
    
    func changeLedStatus(_ clip: Clip, status: LEDStatus) {
        print("ledChange")
        sendCommandToDevice(command: 0x66, hexString: "\(clip.macAddress)\(status.rawValue)")
    }
    
    func startMeasurement(exercise: ExerciseDTO?, weight: Int?) {
        if connectedPeripheral == nil || clips.isEmpty {
            print("measurement not ready")
            return
        }
        let hubIndexes = clips.map { $0.hubIndex }
        let payloadArray = [7,6,5,4,3,2,1,0].map { hubIndexes.contains($0) ? "1" : "0" }
        guard let payloadInt = Int(payloadArray.joined(), radix: 2) else { return }
        
        var payloadStr = String(payloadInt, radix: 16)
        if payloadStr.count < 2 {
            payloadStr = "0" + payloadStr
        }
        print("BluetoothViewModel/startSet: command=0x52, payload=\(payloadStr)")
        sendCommandToDevice(command: 0x52, hexString: payloadStr)
        isReceivingData = true
        
        rawArray = Array(repeating: [], count: 8)
        dataArray = Array(repeating: [], count: 8)
        averageArray = Array(repeating: [], count: 8)
    }
    
    func requestBattInfo() {
        sendCommandToDevice(command: 0x54, payload: 0x00)
    }
    
    func stopMeasurement(restart: Bool, callBack: @escaping () -> (), onFailure: @escaping () -> ()) async {
        guard !clips.isEmpty else {
            print("clips empty")
            return
        }
        if !restart {
            try? await Task.sleep(nanoseconds: 2_800_000_000)
        }
        if bluetoothIsReady {
            while isReceivingData {
                sendCommandToDevice(command: 0x53, payload: 0x00)
                try? await Task.sleep(nanoseconds: 700_000_000)
            }
        }
        
        //        if !restart {
        //            let dataArrayMinSize = rawArray.filter({ $0.count != 0}).map({$0.count}).min() ?? 1
        //            let dataStr = clips.map { clip in
        //                let data = rawArray[clip.hubIndex]
        //                let cut = data[120..<data.index(data.startIndex, offsetBy: dataArrayMinSize)]
        //                return cut.map({
        //                    String(format: "%05d", $0)
        //                }).joined()
        //            }.joined(separator: "_")
        //
        //            if isRVC {
        //                await mvcTrigger(retry: 0) {
        //                    callBack(nil)
        //                    Task {
        //                        await self.fbStorage.uploadRawData(startTime: startTime, eventIndex: eventIndex, setIndex: setIndex, dataStr: dataStr, rvcs: nil, isFailed: false)
        //                    }
        //                } onFailure: {
        //                    onFailure()
        //                    Task {
        //                        await self.fbStorage.uploadRawData(startTime: startTime, eventIndex: eventIndex, setIndex: setIndex, dataStr: dataStr, rvcs: nil, isFailed: true)
        //                    }
        //                }
        //            } else {
        //                Task {
        //                    var timeLimit = 0
        //                    while await reportRepManger.getCount() < repCount && timeLimit < 60 { //리포트가 다 수신될 때 까지 30초 이내로 대기
        //                        try await Task.sleep(nanoseconds: 500_000_000)
        //                        timeLimit += 1
        //                    }
        //                    print("빠져나옴")
        //                    let reportSet = ReportSet(exerciseId: currentExercise!.exerciseId, weight: self.weight, exerciseTime: exerciseTime, reportReps: await reportRepManger.rReps, muscleIds: clips.map({ $0.muscleId }))
        //                    callBack(reportSet)
        //                    await fbStorage.uploadRawData(startTime: startTime, eventIndex: eventIndex, setIndex: setIndex, dataStr: dataStr, rvcs: rvc, isFailed: await reportRepManger.rReps.contains(where: { $0.score == -1 }))
        //                }
        //            }
        //        }
    }
    
    func clearAverageArray() {
        averageArray = Array(repeating: [], count: 8)
    }
    
    func stDataLogicTrigger(who: String, time: Int, dshTime: Int, order: Int, callBack: @escaping ([Float]) -> (), onFailure: @escaping () -> ()) async {
        try? await Task.sleep(nanoseconds: 2_800_000_000)
        
// test
        #if DEBUG
            try? await Task.sleep(nanoseconds: 2_800_000_000)
                    callBack(testStSingleValue) // test
                    return
        #endif
        
//        if !averageArray.filter({ $0.isEmpty }).isEmpty {
//            onFailure()
//        }
        
        print("averageArray Sizes = \(averageArray.map({ $0.count }))")
        let dataArrayMinSize = averageArray.filter({ $0.count != 0}).map({$0.count}).min() ?? 0
        let startingIndex = dataArrayMinSize > 120 ? 120 : dataArrayMinSize // 앞 1.2초 딜레이는 dataArray에 데이터 쌓으면서 없애는데, st는 그냥 쭉 받으니까 앞 120초 잘라줘야함.
        let dataStr = clips.map { clip in
            let data = averageArray[clip.hubIndex]
            let cut = data[0..<data.index(data.startIndex, offsetBy: dataArrayMinSize)]
            return cut.map({
                String(format: "%05d", $0)
            }).joined()
        }.joined(separator: "_") + "/" + clips.map { clip in
            let data = rawArray[clip.hubIndex]
            let cut = data[0..<data.index(data.startIndex, offsetBy: dataArrayMinSize)]
            return cut.map({
                String(format: "%05d", $0)
            }).joined()
        }.joined(separator: "_")
        
        rawArray = Array(repeating: [], count: 8)
        dataArray = Array(repeating: [], count: 8)
        averageArray = Array(repeating: [], count: 8)
        
        HttpRequest(logicURL)
            .setPath("/STTrigger")
            .setParams(name: "who", value: who)
            .setParams(name: "time", value: String(time))
            .setParams(name: "spineCode", value: spineCode[order])
            .setMethod("POST")
            .setBody(dataStr)
            .sendRequest { returnStr in
                let value: [Float] = returnStr.split(separator: ",").map{ Float($0)! }
                print("returnedStr")
                callBack(value)
            } onFailure: {
                print("Failed")
                onFailure()
            }
    }
    
    func stScoreTrigger(who: String, time: Int, dashboardTime: Int, value: [[Float]], callBack: @escaping (ReportST) -> (), onFailure: @escaping () -> ()) async {
        
        let hubId: String = self.hub?.name ?? "noHubName"
        
//        // test
        #if DEBUG
            try? await Task.sleep(nanoseconds: 2_800_000_000)
            callBack(testReportSt)
            return
        #endif
        
        let valueStr = value.map ({ v in
            v.map { String($0) }.joined(separator: ",")
        }).joined(separator: ",")
        
        
        HttpRequest(logicURL)
            .setPath("/STScoreTrigger")
            .setParams(name: "who", value: who)
            .setParams(name: "time", value: String(time))
            .setParams(name: "dshTime", value: String(dashboardTime))
            .setParams(name: "hubId", value: hubId)
            .setMethod("POST")
            .setBody(valueStr)
            .sendRequest { returnStr in
                print("returnedStrScore")
                if let data = returnStr.data(using: .utf8) {
                    do {
                        let reportST = try JSONDecoder().decode(ReportST.self, from: data)
                        print("reportST = \(reportST)")
                        callBack(reportST)
                    } catch {
                        print("Error decoding JSON: \(error)")
                    }
                } else {
                    print("Error converting String to Data")
                    onFailure()
                }
            } onFailure: {
                print("Score Failed")
                onFailure()
            }
    }
    
    func ftDataLogicTrigger(who: String, time: Int, dashboardTime: Int, retryCount: Int, callBack: @escaping (ReportFTDTO, [[Float]]) -> (), onFailure: @escaping (Int) -> ()) async{
        await stopMeasurement(restart: false, callBack: {}, onFailure: {})
        
//        callBack(testReportFt, testRawDatas) // test
//        return
        
        let hubId: String = self.hub?.name ?? "noHubName"
        
        let dataArrayMinSize = averageArray.filter({ $0.count != 0}).map({$0.count}).min() ?? 0
        let dataStr = clips.map { clip in
            let data = averageArray[clip.hubIndex]
            let cut = data[0..<data.index(data.startIndex, offsetBy: dataArrayMinSize)]
            return cut.map({
                String(format: "%05d", $0)
            }).joined()
        }.joined(separator: "_") + "/" + clips.map { clip in
            let data = rawArray[clip.hubIndex]
            let cut = data[0..<data.index(data.startIndex, offsetBy: dataArrayMinSize)]
            return cut.map({
                String(format: "%05d", $0)
            }).joined()
        }.joined(separator: "_")
        print("averageArrayMinSize = \(dataArrayMinSize)")
        
        let muscleIdsStr = "\(clips.map { String($0.muscleId) }.joined(separator: ","))"
        print(muscleIdsStr)
        
        rawArray = Array(repeating: [], count: 8)
        dataArray = Array(repeating: [], count: 8)
        averageArray = Array(repeating: [], count: 8)
        
        HttpRequest(logicURL)
            .setPath("/FTTrigger")
            .setParams(name: "who", value: who)
            .setParams(name: "time", value: String(time))
            .setParams(name: "dshTime", value: String(dashboardTime))
            .setParams(name: "mids", value: muscleIdsStr)
            .setParams(name: "hubId", value: hubId)
            .setMethod("POST")
            .setBody(dataStr)
            .sendRequest { returnStr in
                // report({...}) + rawData(4자리 * 0.1 , 구분)
                let parts = returnStr.split(separator: "/")
                guard let reportStr = parts.first, let rawDataStrs = parts.last?.split(separator: "_") else {
                    onFailure(retryCount)
                    return
                }
                
                var rawDatas: [[Float]] = []
                for rawDataStr in rawDataStrs {
                    let rawData: [Float] = rawDataStr.split(separator: ",").map{ Float($0)! }
                    rawDatas.append(rawData)
                }
                
                print("returnedStr")
                if let data = reportStr.data(using: .utf8) {
                    do {
                        let reportEntity = try JSONDecoder().decode(ReportFTEntity.self, from: data)
                        print("reportFT = \(reportEntity)")
                        let reportDTO = ReportFTDTO.fromEntity(entity: reportEntity, muscles: ExerciseRepository.shared.muscles ?? ftMuscles)
                        callBack(reportDTO, rawDatas)
                    } catch {
                        print("Error decoding JSON: \(error)")
                    }
                    
                } else {
                    print("Error converting String to Data")
                    onFailure(retryCount)
                }
            } onFailure: {
                print("Failed")
                onFailure(retryCount)
            }
        
    }
    
    func etDataLogicTrigger(reportET: ReportETDTO, time: Int, retryCount: Int, callBack: @escaping (ReportETSetDTO, [[Float]]) -> (), onFailure: @escaping (Int) -> ()) async{
        await stopMeasurement(restart: false, callBack: {}, onFailure: {})
        
//        callBack(testReportETSet, testRawDatas) // test
//        return
        
        let hubId: String = self.hub?.name ?? "noHubName"
        
        let dataArrayMinSize = averageArray.filter({ $0.count != 0}).map({$0.count}).min() ?? 0
        let dataStr = clips.map { clip in
            let data = averageArray[clip.hubIndex]
            let cut = data[0..<data.index(data.startIndex, offsetBy: dataArrayMinSize)]
            return cut.map({
                String(format: "%05d", $0)
            }).joined()
        }.joined(separator: "_") + "/" + clips.map { clip in
            let data = rawArray[clip.hubIndex]
            let cut = data[0..<data.index(data.startIndex, offsetBy: dataArrayMinSize)]
            return cut.map({
                String(format: "%05d", $0)
            }).joined()
        }.joined(separator: "_")
        print("averageArrayMinSize = \(dataArrayMinSize)")
        
        let muscleIdsStr = "\(clips.map { String($0.muscleId) }.joined(separator: ","))"
        print(muscleIdsStr)
        
        rawArray = Array(repeating: [], count: 8)
        dataArray = Array(repeating: [], count: 8)
        averageArray = Array(repeating: [], count: 8)
        
        HttpRequest(logicURL)
            .setPath("/ETTrigger")
            .setParams(name: "who", value: reportET.who)
            .setParams(name: "reportETId", value: reportET.reportId)
            .setParams(name: "exid", value: String(reportET.exerciseId))
            .setParams(name: "time", value: String(time))
            .setParams(name: "mids", value: muscleIdsStr)
            .setParams(name: "hubId", value: hubId)
            .setMethod("POST")
            .setBody(dataStr)
            .sendRequest { returnStr in
                // report({...}) + rawData(4자리 * 0.1 , 구분)
                // TODO reportId도 받아옴
                let parts = returnStr.split(separator: "/")
                guard let documentId = parts.first, let reportStr = parts[safe: 1], let rawDataStrs = parts[safe: 2]?.split(separator: "_") else {
                    onFailure(retryCount)
                    return
                }
                
                var rawDatas: [[Float]] = []
                for rawDataStr in rawDataStrs {
                    let rawData: [Float] = rawDataStr.split(separator: ",").map{ Float($0)! }
                    rawDatas.append(rawData)
                }
                
                if let data = reportStr.data(using: .utf8) {
                    do {
                        let reportEntity = try JSONDecoder().decode(ReportETSetEntity.self, from: data)
                        print("reportETSet = \(reportEntity)")
                        let reportDTO = ReportETSetDTO.fromEntity(
                            reportSetId: String(documentId),
                            who: reportET.who,
                            entity: reportEntity,
                            muscles: self.clips.map{ ExerciseRepository.shared.getMusclesById(mid: $0.muscleId)! }
                        )
                        callBack(reportDTO, rawDatas)
                    } catch {
                        print("Error decoding JSON: \(error)")
                    }
                    
                } else {
                    print("Error converting String to Data")
                    onFailure(retryCount)
                }
            } onFailure: {
                print("Failed")
                onFailure(retryCount)
            }
    }
    
    func btDataLogicTrigger(reportBT: ReportBTDTO, time: Int, retryCount: Int, callBack: @escaping (ReportBTSetDTO) -> (), onFailure: @escaping (Int) -> ()) async{
        await stopMeasurement(restart: false, callBack: {}, onFailure: {})
        
        let hubId: String = self.hub?.name ?? "noHubName"
        
        let dataArrayMinSize = averageArray.filter({ $0.count != 0}).map({$0.count}).min() ?? 0
        let dataStr = clips.map { clip in
            let data = averageArray[clip.hubIndex]
            let cut = data[0..<data.index(data.startIndex, offsetBy: dataArrayMinSize)]
            return cut.map({
                String(format: "%05d", $0)
            }).joined()
        }.joined(separator: "_") + "/" + clips.map { clip in
            let data = rawArray[clip.hubIndex]
            let cut = data[0..<data.index(data.startIndex, offsetBy: dataArrayMinSize)]
            return cut.map({
                String(format: "%05d", $0)
            }).joined()
        }.joined(separator: "_")
        print("averageArrayMinSize = \(dataArrayMinSize)")
        
        rawArray = Array(repeating: [], count: 8)
        dataArray = Array(repeating: [], count: 8)
        averageArray = Array(repeating: [], count: 8)
        
        #if DEBUG
            callBack(testReportBTSet) // test
            return
        #endif
        
        HttpRequest(logicURL)
            .setPath("/BTTrigger")
            .setParams(name: "who", value: reportBT.who)
            .setParams(name: "reportBTId", value: reportBT.reportId)
            .setParams(name: "dshTime", value: String(reportBT.dashboardTime))
            .setParams(name: "time", value: String(time))
            .setParams(name: "hubId", value: hubId)
            .setMethod("POST")
            .setBody(dataStr)
            .sendRequest { returnStr in
                let parts = returnStr.split(separator: "/")
                guard let documentId = parts.first, let reportStr = parts[safe: 1], let rawDataStrs = parts[safe: 2]?.split(separator: "_") else {
                    onFailure(retryCount)
                    return
                }
                
                var rawDatas: [[Float]] = []
                for rawDataStr in rawDataStrs {
                    let rawData: [Float] = rawDataStr.split(separator: ",").map{ Float($0)! }
                    rawDatas.append(rawData)
                }
                
                if let data = reportStr.data(using: .utf8) {
                    do {
                        let reportEntity = try JSONDecoder().decode(ReportBTSetEntity.self, from: data)
                        print("reportBTSet = \(reportEntity)")
                        let reportSetDTO = ReportBTSetDTO.fromEntity(
                            reportSetId: String(documentId),
                            who: reportBT.who,
                            entity: reportEntity,
                            rawData: rawDatas
                        )
                        callBack(reportSetDTO)
                    } catch {
                        print("Error decoding JSON: \(error)")
                    }
                    
                } else {
                    print("Error converting String to Data")
                    onFailure(retryCount)
                }
            } onFailure: {
                print("Failed")
                onFailure(retryCount)
            }
    }
    
    func dashboardTrigger(
        who: String,
        dashboardTime: Int,
        reportSTs: [ReportST],
        reportFTs: [ReportFTDTO],
        reportETs: [ReportETDTO],
        reportBTs: [ReportBTDTO],
        callBack: @escaping (DashboardDTO) -> (),
        onFailure: @escaping () -> ()
    ) {
        let reportSTsStr = reportSTs.compactMap({
            if let data = try? JSONEncoder().encode($0) {
                String(data: data, encoding: .utf8)
            } else {
                nil
            }
        }).joined(separator: "_")
        let reportFTsStr = reportFTs.compactMap({
            if let data = try? JSONEncoder().encode($0.toEntity()) {
                String(data: data, encoding: .utf8)
            } else {
                nil
            }
        }).joined(separator: "_")
        let reportETsStr = reportETs.compactMap({
            if let data = try? JSONEncoder().encode($0.toEntity()) {
                String(data: data, encoding: .utf8)
            } else {
                nil
            }
        }).joined(separator: "_")
        let reportETSetsStr = reportETs.compactMap({
            if let data = try? JSONEncoder().encode($0.reportSets?.compactMap({ $0?.toEntity() })) {
                String(data: data, encoding: .utf8)
            } else {
                nil
            }
        }).joined(separator: "_")
        let reportBTsStr = reportBTs.compactMap ({
            if let data = try? JSONEncoder().encode($0.toEntity()) {
                String(data: data, encoding: .utf8)
            } else {
                nil
            }
        }).joined(separator: "_")
        let reportBTSetsStr = reportBTs.compactMap({
            if let data = try? JSONEncoder().encode($0.reportSets.compactMap({ $0?.toEntity() })) {
                String(data: data, encoding: .utf8)
            } else {
                nil
            }
        }).joined(separator: "_")
        
        let body = [reportSTsStr, reportFTsStr, reportETsStr, reportETSetsStr, reportBTsStr, reportBTSetsStr].joined(separator: "/")
        
        print("BluetoothViewModel/dashboardTrigger: body = \(body)")
        #if DEBUG
            callBack(testDashboard1) // test
            return
        #endif
        
        print("BluetoothViewModel/dashboardTrigger: triggered")
        HttpRequest(logicURL)
            .setPath("/dashboardTrigger")
            .setParams(name: "totalTime", value: String(Int(Date().timeIntervalSince1970) - dashboardTime))
            .setMethod("POST")
            .setBody(body)
            .sendRequest { returnStr in
                if let data = returnStr.data(using: .utf8) {
                    do {
                        let entity = try JSONDecoder().decode(DashboardEntity.self, from: data)
                        let dashboard = DashboardDTO.fromEntity(entity: entity, reportSTs: reportSTs, reportFTs: reportFTs, reportETs: reportETs, reportBTs: reportBTs)
                        callBack(dashboard)
                    } catch {
                        print("BluetoothViewmodel/dashboardTrigger: Error decoding JSON: \(error)")
                    }
                } else {
                    print("BluetoothViewmodel/dashboardTrigger: Error converting String to Data")
                    onFailure()
                }
            } onFailure: {
                print("BluetoothViewmodel/dashboardTrigger: Failed getting Response")
                onFailure()
            }
    }
    
    func refreshAll(hubDisconnect: Bool = false) async{
        if connectedPeripheral != nil{
            if let tempClip = self.tempClip {
                changeLedStatus(tempClip, status: .blue)
                await clearTemp()
            }
            for clip in self.clips {
                try? await Task.sleep(nanoseconds: 300_000_000)
                changeLedStatus(clip, status: .blue)
            }
            try? await Task.sleep(nanoseconds: 300_000_000)
            if hubDisconnect{
                centralManager.cancelPeripheralConnection(connectedPeripheral!)
                print("BluetoothViewModel/refreshAll: hubDisconnect")
            }
        }
        DispatchQueue.main.async{
            self.clips = []
            if hubDisconnect {
                self.hub = nil
            }
        }
        mvc = nil
        print("BluetoothViewModel/refreshAll: triggered")
    }
    
    func clearTemp() async {
        print("BluetoothViewModel/clearTemp: triggered")
        if let temp = self.tempClip {
            try? await Task.sleep(nanoseconds: 300_000_000)
            changeLedStatus(temp, status: .blue)
        }
        DispatchQueue.main.async {
            self.tempClip = nil
            print("BluetoothViewModel/clearTemp: cleared, tempClip = \(self.tempClip)")
        }
    }
    
    enum LEDStatus: String {
        case whiteBlink = "01"
        case white = "02"
        case blue = "00"
    }
}
