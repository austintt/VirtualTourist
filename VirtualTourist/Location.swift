//
//  Location.swift
//  VirtualTourist
//
//  Created by Austin Tooley on 8/19/17.
//  Copyright © 2017 Austin Tooley. All rights reserved.
//

import Foundation

struct Location {
    var long: Double
    var lat: Double
    
    init(lat: Double, long: Double) {
        self.lat = lat
        self.long = long
    }
}
