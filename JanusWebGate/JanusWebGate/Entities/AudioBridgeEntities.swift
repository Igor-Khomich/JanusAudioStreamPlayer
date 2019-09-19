//
//  AudioBridgeUserConfig.swift
//  JanusWebGate
//
//  Created by Igor Khomich on 9/19/19.
//  Copyright © 2019 Igor Khomich. All rights reserved.
//

import Foundation

public struct AudioBridgeUserConfig: Codable {
    let request: String = "configure"
    let muted: Bool
    let displayName: String?
    let quality: UInt8?
    let volume: UInt8?

    enum CodingKeys : String, CodingKey {
        case request = "request"
        case muted = "muted"
        case displayName = "display"
        case quality = "quality"
        case volume = "volume"
    }
    
    // volume - 1..100..??  default 100
    // quality - 1..10  default 4
    public init(userName: String? = nil, muted: Bool = false, volume: UInt8? = nil, quality: UInt8? = nil) {
        self.displayName = userName
        self.muted = muted
        self.volume = volume

        if let quality = quality {
            self.quality = quality < UInt8(11) ? quality : 4
        } else {
            self.quality = nil
        }
        
    }
}
