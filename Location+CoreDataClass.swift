//
//  Location+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Austin Tooley on 8/19/17.
//  Copyright © 2017 Austin Tooley. All rights reserved.
//

import Foundation
import CoreData

@objc(Location)
public class Location: NSManagedObject {

    convenience init(lat: Double = 29.4241, long: Double = 98.4936, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: "Location", in: context) {
            self.init(entity: ent, insertInto: context)
            self.lat = lat
            self.long = long
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
}
