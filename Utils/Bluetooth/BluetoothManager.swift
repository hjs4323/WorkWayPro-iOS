//
//  BluetoothManager.swift
//  WorkwayVer2
//
//  Created by 김성욱 on 7/11/24.
//

import Foundation
import CoreBluetooth
import UIKit
import SwiftUI
import Combine

/// 블루투스 통신을 담당할 시리얼을 클래스로 선언합니다. CoreBluetooth를 사용하기 위한 프로토콜을 추가해야합니다.
class BluetoothManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    static let shared = BluetoothManager()
    /// serial을 초기화할 떄 호출하여야합니다. 시리얼은 nil이여서는 안되기 때문에 항상 초기화후 사용해야 합니다.
    override init() {
        // hub, clip(clip),connectedPeripheral, writeCharacteristic, writeType 넘겨줘야할지도
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        print("cbmanager init state = \(centralManager.state)")
    }
    
    /// centralManager은 블루투스 주변기기를 검색하고 연결하는 역할을 수행합니다.
    var centralManager : CBCentralManager!
    
    /// pendingPeripheral은 현재 연결을 시도하고 있는 블루투스 주변기기를 의미합니다.
    var pendingPeripheral : CBPeripheral?
    
    /// connectedPeripheral은 연결에 성공된 기기를 의미합니다. 기기와 통신을 시작하게되면 이 객체를 이용하게됩니다.
    var connectedPeripheral : CBPeripheral?
    
    /// 데이터를 주변기기에 보내기 위한 characteristic을 저장하는 변수입니다.
    weak var writeCharacteristic: CBCharacteristic?
    
    /// 데이터를 주변기기에 보내는 type을 설정합니다. withResponse는 데이터를 보내면 이에 대한 답장이 오는 경우입니다. withoutResponse는 반대로 데이터를 보내도 답장이 오지 않는 경우입니다.
    private var writeType: CBCharacteristicWriteType = .withoutResponse
    
    /// serviceUUID는 Peripheral이 가지고 있는 서비스의 UUID를 뜻합니다. 거의 모든 HM-10모듈이 기본적으로 갖고있는 FFE0으로 설정하였습니다. 하나의 기기는 여러개의 serviceUUID를 가질 수도 있습니다.
    var serviceUUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
    
    /// characteristicUUID는 serviceUUID에 포함되어있습니다. 이를 이용하여 데이터를 송수신합니다. FFE0 서비스가 갖고있는 FFE1로 설정하였습니다. 하나의 service는 여러개의 characteristicUUID를 가질 수 있습니다.
    var UUID_RX = CBUUID(string : "beb5483e-36e1-4688-b7f5-ea07361b26a9")
    var UUID_TX = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")
    var characteristicsUUIDs: [CBUUID] = [
        CBUUID(string : "beb5483e-36e1-4688-b7f5-ea07361b26a9"),
        CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")
    ]
    
    var bluetoothIsReady: Bool = false
    
    var isReceivingData: Bool = false
    var rawArray: [[Int]] = Array(repeating: [], count: 8)
    var dataArray: [[Int]] = Array(repeating: [], count: 8)
    var averageArray: [[Int]] = Array(repeating: [], count: 8)
    
    @Published var discoveredPeripherals: [CBPeripheral] = []
    @Published var hub: Hub? = nil
    @Published var clips: [Clip] = []
    @Published var tempClip: Clip? = nil
    private var isAttachingClip: Bool = false
    var mvc: [Float]?
    
    var scanTimer: Timer?
    
    func setIsAttachingClip(_ nextVal: Bool) {
        print("BluetoothManager/setIsAttachingClip: to \(nextVal)")
        self.isAttachingClip = nextVal
    }
    
    private func setBatteries(batterys: [Float?]) {
        if clips.isEmpty || hub == nil {
            return
        }
        for var clip in clips {
            clip.battery = batterys[clip.hubIndex]
        }
        hub?.battery = batterys.last!
        
        if !batterys.filter({ $0 != nil && $0! < 3.4 }).isEmpty {
            if let hub = hub, let battery = hub.battery {
                print("hub Batt = \(battery)")
            }
        }
    }
    
    /// 기기 검색을 시작합니다. 연결이 가능한 모든 주변기기를 serviceUUID를 통해 찾아냅니다.
    func startScan(withDuration duration: TimeInterval) {
        
        print("blutooth state = \(centralManager.state)")
        guard centralManager.state == .poweredOn else { return }
        
        // CBCentralManager의 메서드인 scanForPeripherals를 호출하여 연결가능한 기기들을 검색합니다. 이 떄 withService 파라미터에 nil을 입력하면 모든 종류의 기기가 검색되고, 지금과 같이 serviceUUID를 입력하면 특정 serviceUUID를 가진 기기만을 검색합니다.
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        print("scan 시작")
        scanTimer = Timer.scheduledTimer(timeInterval: duration, target: self, selector: #selector(stopScan), userInfo: nil, repeats: false)

        //이건 이미 연결돼있는 peripheral을 불러오는거같음.
        let peripherals = centralManager.retrieveConnectedPeripherals(withServices: [serviceUUID])
        
        for peripheral in peripherals {
            if(!discoveredPeripherals.contains(peripheral)){
                print(peripheral.name!)
                discoveredPeripherals.append(peripheral)
            }
        }
    }
    
    /// 기기 검색을 중단합니다.
    @objc func stopScan() {
        centralManager.stopScan()
        scanTimer?.invalidate()
        scanTimer = nil
    }
    
    /// 파라미터로 넘어온 주변 기기를 CentralManager에 연결하도록 시도합니다.
    func connectToPeripheral(_ peripheral : CBPeripheral) {
        // 연결 실패를 대비하여 현재 연결 중인 주변 기기를 저장합니다.
        pendingPeripheral = peripheral
        centralManager.connect(peripheral, options: nil)
    }
    
    // CBCentralManagerDelegate에 포함되어 있는 메서드입니다.
    // central 기기의 블루투스가 켜져있는지, 꺼져있는지 확인합니다. 확인하여 centralManager.state의 값을 .powerOn 또는 .powerOff로 변경합니다.
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        pendingPeripheral = nil
        connectedPeripheral = nil
        switch central.state {
        case .poweredOn:
            // Bluetooth가 켜져 있는 경우
            print("Bluetooth is powered on")
            
        case .poweredOff:
            // Bluetooth가 꺼져 있는 경우
            bluetoothIsReady = false
            print("Bluetooth is powered off")
            
        case .resetting:
            // Bluetooth가 재설정 중인 경우
            print("Bluetooth is resetting")
        case .unauthorized:
            // Bluetooth 권한이 거부된 경우
            print("Bluetooth access is unauthorized")
        case .unknown:
            // Bluetooth 상태를 알 수 없는 경우
            print("Bluetooth state is unknown")
        case .unsupported:
            // Bluetooth가 지원되지 않는 경우
            print("Bluetooth is unsupported")
        @unknown default:
            print("Unknown Bluetooth state")
        }
    }
    
    
    // 기기가 검색될 때마다 호출되는 메서드입니다.
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // RSSI는 기기의 신호 강도를 의미합니다.
        // 기기가 검색될 때마다 뷰에 반영합니다.
        if peripheral.name?.contains("WORKWAY") == true && !discoveredPeripherals.contains(peripheral){
            discoveredPeripherals.append(peripheral)
        }
    }
    
    
    // 기기가 연결되면 호출되는 메서드입니다.
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        pendingPeripheral = nil
        connectedPeripheral = peripheral
        
        print("연결은 성공, discover 시작")
        
        // peripheral의 Service들을 검색합니다.파라미터를 nil으로 설정하면 peripheral의 모든 service를 검색합니다.
        peripheral.discoverServices([serviceUUID])
    }
    
    
    // service 검색에 성공 시 호출되는 메서드입니다.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            // 검색된 모든 service에 대해서 characteristic을 검색합니다. 파라미터를 nil로 설정하면 해당 service의 모든 characteristic을 검색합니다.
            peripheral.discoverCharacteristics(characteristicsUUIDs, for: service)
        }
    }
    
    // characteristic 검색에 성공 시 호출되는 메서드입니다.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        var isNotifySet: Bool = false
        
        for characteristic in service.characteristics! {
            // 검색된 모든 characteristic에 대해 characteristicUUID를 한번 더 체크하고, 일치한다면 peripheral을 구독하고 통신을 위한 설정을 완료합니다.
            switch characteristic.uuid {
            case UUID_TX:
                // 데이터를 보내기 위한 characteristic을 저장합니다.
                writeCharacteristic = characteristic
                // 데이터를 보내는 타입을 설정합니다. 이는 주변기기가 어떤 type으로 설정되어 있는지에 따라 변경됩니다.
                writeType = characteristic.properties.contains(.write) ? .withResponse :  .withoutResponse
                print("set writeCharacteristic \(characteristic.uuid)")
            case UUID_RX:
                // 해당 기기의 데이터를 구독합니다.
                peripheral.setNotifyValue(true, for: characteristic)
                print("setNotifyValue. \(characteristic.uuid)")
                isNotifySet = true
            default:
                continue
            }
        }
        // 주변 기기와 연결 완료 시 동작하는 코드를 여기에 작성합니다.
        if writeCharacteristic != nil && isNotifySet == true {
            bluetoothIsReady = true
            print("writecharacteristic 등록 성공, peripheral=\(peripheral)")
            hub = Hub(name: peripheral.name ?? "WorkWay-Default")
            sendCommandToDevice(command: 0x61, payload: 0x00)
            self.discoveredPeripherals = []
            self.connectedPeripheral = peripheral
            self.hub = Hub(name: peripheral.name ?? "WorkWay-Default")
            clips.forEach { clip in
                changeLedStatus(clip, status: .white)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        bluetoothIsReady = false
        self.hub?.connection = false
    }
    
    //여기부터 전송코드
    
    ///0x00으로 적기 숫자로 적어
    func sendCommandToDevice(command: Int, payload: Int) {
        let STX = "80AA"
        let payloadSize = command == 0x55 ? 8 : command == 0x60 ? 1 + 2 * String(payload, radix: 16).count : 2
        let data = String(format: "%02X", command) + String(format: "%0\(payloadSize)X", payload)
        guard let length = data.hexToData()?.count else { return } //바이트 길이
        let lengthStr = String(format: "%04X", length)
        let checkSum = String(format: "%04X", (lengthStr + data.hexToData()!.hexEncodedString(.upperCase)).components(withMaxLength: 2).map({ UInt($0, radix: 16)!}).reduce(UInt(0), +) )
        let ETX = "BB81"
        
        guard let packet = (STX + lengthStr + data + checkSum + ETX).hexToData() else { return }
        
        print("sendPacket packetStr = \(STX + lengthStr + data + checkSum + ETX)")
        
        sendDataToDevice(packet)
    }
    
    func sendCommandToDevice(command: Int, hexString: String) {
        let STX = "80AA"
        let data = String(format: "%02X", command) + hexString
        guard let length = data.hexToData()?.count else {
            print("BluetoothManager/sendCommandToDevice:length hexToData Error")
            return
        } //바이트 길이
        let lengthStr = String(format: "%04X", length)
        let checkSum = String(format: "%04X", UInt(length) + UInt(data.hexToData()!.hexEncodedString(.upperCase), radix: 16)!).takeLast(4)
        let ETX = "BB81"
        
        guard let packet = (STX + lengthStr + data + checkSum + ETX).hexToData() else {
            print("BluetoothManager/sendCommandToDevice:packet hexToData Error")
            return
        }
        
        print("sendPacket packetStr = \(STX + lengthStr + data + checkSum + ETX)")
        
        sendDataToDevice(packet)
    }
    
    /// 데이터를 주변기기에 전송합니다.
    func sendDataToDevice(_ data: Data) {
        guard bluetoothIsReady else {
            print("BluetoothManager/sendDataToDevice: bluetooth Not Ready")
            return
        }
        connectedPeripheral!.writeValue(data, for: writeCharacteristic!, type: writeType)
    }
    
    private func decodePacket(packet: String) -> String? {
        guard packet.count > 16 else { return nil }
        let STX = packet[packet.startIndex..<packet.index(packet.startIndex, offsetBy: 4)]
        let length = packet[packet.index(packet.startIndex, offsetBy: 4)..<packet.index(packet.startIndex, offsetBy: 8)]
        let lengthInt = Int(length, radix: 16)!
        let data = packet[packet.index(packet.startIndex, offsetBy: 8)..<packet.index(packet.endIndex, offsetBy: -8)]
        let checkSum = packet[packet.index(packet.endIndex, offsetBy: -8)..<packet.index(packet.endIndex, offsetBy: -4)]
        let ETX = packet[packet.index(packet.endIndex, offsetBy: -4)..<packet.endIndex]
        
        if data.count / 2 != lengthInt || STX != "80AA" || ETX != "BB81" {
            print("lengthError")
            return nil
        }
        return String(data)
    }
    
    // peripheral으로부터 데이터를 전송받으면 호출되는 메서드입니다.
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error {
            print("데이터 수신 에러 ", error)
        }
        // 전송받은 데이터가 존재하는지 확인합니다.
        let data = characteristic.value
        guard data != nil else {
            print("데이터 nil")
            return
        }
        
        // 데이터를 String으로 변환하고, 변환된 값을 파라미터로 한 delegate함수를 호출합니다.
        if let message = data?.hexEncodedString(.upperCase) {
            guard let data = decodePacket(packet: message) else { return }
            print("BluetoothManager/didUpdateValueFor: data decoded = \(data)")
            
            let command = String(data.take(2))
            let payload = String(data.dropFirst(2))
            
            switch command {
            case "E0":
                if payload.takeLast(2) != "00" { print("에러") }
                if payload.take(2) == "53" {
                    isReceivingData = false
                }
                
            case "A0":
                guard let packetNum = Int(payload.take(8), radix: 16) else { return }
//                let attachmentInfo = payload.takeLast(2)
                let allData = String(payload[payload.index(payload.startIndex, offsetBy: 8)..<payload.index(payload.endIndex, offsetBy: -2)])
                dataReceived(allData: allData, hubIndexes: clips.map({ $0.hubIndex }), packetNum: packetNum)
                
            case "A3":
                print("A3, hubINdex = \(Int(payload.takeLast(4).dropLast(2), radix: 16))")
                guard let hubIndex = Int(payload.takeLast(4).dropLast(2), radix: 16) else { return }
                let macAddress = String(payload.take(12))
                let batteryStr = payload.takeLast(2)
                guard let battery = PacketDecode.battDecode(batteryStr) else { return }
                print("hubIndex = \(hubIndex), macAdd = \(macAddress), batt = \(battery)")
                
                if let index = clips.firstIndex(where: { $0.macAddress == macAddress }) {
                    changeLedStatus(clips[index], status: .white)
                }
                else if !self.clips.map({$0.macAddress}).contains(macAddress) && isAttachingClip {
                    Task {
                        if tempClip != nil {
                            changeLedStatus(tempClip!, status: .blue)
                            try? await Task.sleep(nanoseconds: 300_000_000)
                        }
                        DispatchQueue.main.async { [self] in
                            self.tempClip = Clip(macAddress: macAddress, muscleId: 0, battery: battery, hubIndex: hubIndex)
                            self.changeLedStatus(tempClip!, status: .whiteBlink)
                        }
                    }
                }
                
            case "A1":
                let batteryStr = payload.components(withMaxLength: 2)
                let battsCoded = batteryStr.enumerated().map { (index, batt) in
                    let battCoded = PacketDecode.battDecode(batt)
                    return battCoded
                }
                setBatteries(batterys: battsCoded)
            case "A5":
                let macAddress = payload.dropLast(2)
                let status = payload.takeLast(2)
                //지금은 끊어진거만 보는데, 정상 연결을 어디 저장해놓으면 연결 가능한 모듈을 확인할 수 있음
                
                if let index = clips.firstIndex(where: { $0.macAddress == macAddress}) {
                    clips[index].connection = status == "01"
                }
                if let changedClip = clips.first(where: { $0.macAddress == macAddress}) {
                    Task {
                        try? await Task.sleep(nanoseconds: 1_000_000_000)
                        changeLedStatus(changedClip, status: status == "01" ? .white : .blue)
                    }
                }
                
            default:
                print("BluetoothManager/didUpdateValueFor: default")
            }
        } else {
            print("데이터 인코딩 실패")
            return
        }
    }
    
    private func dataReceived(allData: String, hubIndexes: [Int], packetNum: Int) {
        let weight = [0.29395525, 0.21062814, 0.15092166, 0.10814009, 0.07748576, 0.05552097, 0.03978252, 0.02850542, 0.02042503, 0.01463517]
        allData.components(withMaxLength: 32).forEach { aSample in
            let intData = aSample.components(withMaxLength: 4).map { dataStr in
                Int(dataStr, radix: 16) ?? 0
            }
            intData.enumerated().forEach({ (hubIndex, i) in
                rawArray[hubIndex].append(i)
                if rawArray[hubIndex].count <= 120 {
                    return
                }
                if i > 40000 || i == 0 || (dataArray[hubIndex].count >= 10 && (i - dataArray[hubIndex].last!) > 5000) {
                    let replace = dataArray[hubIndex].takeLast(10).enumerated().map { (weightIndex, weightVal) in
                        Double(weightVal) * weight[weightIndex]
                    }.reduce(0.0, +)
                    dataArray[hubIndex].append(Int(replace))
                } else {
                    dataArray[hubIndex].append(i)
                }
                if dataArray[hubIndex].count > 25 {
                    let beforeAverage = dataArray[hubIndex]
                    let recent26 = beforeAverage.takeLast(26)
                    let average = Int(recent26.average())
                    
                    averageArray[hubIndex].append(average)
                }
            })
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        // writeType이 .withResponse일 때, 블루투스 기기로부터의 응답이 왔을 때 호출되는 메서드입니다.
        // 필요한 로직을 작성하면 됩니다.
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        // 블루투스 기기의 신호 강도를 요청하는 peripheral.readRSSI()가 호출하는 메서드입니다.
        // 신호 강도와 관련된 코드를 작성합니다.
        // 필요한 로직을 작성하면 됩니다.
    }
    
    func disconnect() async {
        for i in 0..<8 {
            if let clip = clips.first(where: { $0.hubIndex == i }) {
                changeLedStatus(clip, status: .blue)
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
        }
        if let connectedPeripheral {
            centralManager.cancelPeripheralConnection(connectedPeripheral)
        }
    }
}
