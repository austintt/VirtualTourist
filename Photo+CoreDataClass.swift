//
//  Photo+CoreDataClass.swift
//  VirtualTourist
//
//  Created by Austin Tooley on 8/19/17.
//  Copyright © 2017 Austin Tooley. All rights reserved.
//

import Foundation
import CoreData

@objc(Photo)
public class Photo: NSManagedObject {

    convenience init(url: String, context: NSManagedObjectContext) {
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: ent, insertInto: context)
            self.url = url
        } else {
            fatalError("Unable to find Entity name!")
        }
    }
}
