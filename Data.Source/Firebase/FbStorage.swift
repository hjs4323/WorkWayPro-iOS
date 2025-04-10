//
//  FbStorage.swift
//  WorkwayVer2
//
//  Created by 김성욱 on 7/24/24.
//

import Foundation
import FirebaseCore
import FirebaseStorage
import FirebaseAuth
import Gzip

private let ONE_MEGABYTE: Int64 = 1024 * 1024

enum FBStorageDirs: String {
    case RAW = "raw"
    case FTGRAPH = "ftgraph"
    case ETGRAPH = "etgraph"
    case BTGRAPH = "btgraph"
}

struct FbStorage {
    private let ref = Storage.storage().reference()
    
    func getGraphData(dir: FBStorageDirs, who: String, time: Int, callBack: @escaping (Data?) -> ()) {
        let storageRef = ref
            .child(dir.rawValue)
            .child(who)
            .child(String(time))
        
        storageRef.getData(maxSize: ONE_MEGABYTE) { data, error in
            if let error {
                print("FBStorage/getGraphData: error downloading Data \(error)")
            } else {
                if let dataUnzipped = try? data?.gunzipped() {
                    callBack(dataUnzipped)
                } else {
                    callBack(nil)
                    print("FBStorage/getGraphData: error gunzipping")
                }
            }
        }
    }
}
