//
//  Utilites.swift
//  JanusWebGate
//
//  Created by Igor Khomich on 11/25/18.
//  Copyright © 2018 Igor Khomich. All rights reserved.
//

import Foundation

class Utilites {
    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0...length-1).map{ _ in letters.randomElement()! })
    }
}
