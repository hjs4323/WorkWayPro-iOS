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
    }
    
    func clearAverageArray() {
        averageArray = Array(repeating: [], count: 8)
    }
    
    func stDataLogicTrigger(who: String, time: Int, dshTime: Int, order: Int, callBack: @escaping ([Float]) -> (), onFailure: @escaping () -> ()) async {
        // 특허 관련해서 주석으로 대체
        // st 점수화를 위해 1 부위의 측정값을 서버에 전송한 후 결과 값을 받아 콜백
    }
    
    func stScoreTrigger(who: String, time: Int, dashboardTime: Int, value: [[Float]], callBack: @escaping (ReportST) -> (), onFailure: @escaping () -> ()) async {
        // 특허 관련해서 주석으로 대체
        // stDataLogicTrigger로 생성된 모든 부위의 결과 값을 서버에 전송한 후 결과 값으로 레포트를 받아 콜백
    }
    
    func ftDataLogicTrigger(who: String, time: Int, dashboardTime: Int, retryCount: Int, callBack: @escaping (ReportFTDTO, [[Float]]) -> (), onFailure: @escaping (Int) -> ()) async{
        // 특허 관련해서 주석으로 대체
        // ft 점수화를 위해 측정값을 서버에 전송한 후 결과 값으로 레포트를 받아 콜백
    }
    
    func etDataLogicTrigger(reportET: ReportETDTO, time: Int, retryCount: Int, callBack: @escaping (ReportETSetDTO, [[Float]]) -> (), onFailure: @escaping (Int) -> ()) async{
        await stopMeasurement(restart: false, callBack: {}, onFailure: {})
        // 특허 관련해서 주석으로 대체
        // et 점수화를 위해 측정값을 서버에 전송한 후 결과 값으로 레포트를 받아 콜백
    }
    
    func btDataLogicTrigger(reportBT: ReportBTDTO, time: Int, retryCount: Int, callBack: @escaping (ReportBTSetDTO) -> (), onFailure: @escaping (Int) -> ()) async{
        // 특허 관련해서 주석으로 대체
        // bt 점수화를 위해 측정값을 서버에 전송한 후 결과 값으로 레포트를 받아 콜백
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
        // 특허 관련해서 주석으로 대체
        // 이름, 시간, 레포트를 이용해 대시보드를 반환받아 콜백
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
