//
//  Item.swift
//  container.desktop
//
//  Created by Julien DUCHON on 17/11/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
