//
//  MapViewExtension.swift
//  VirtualTourist
//
//  Created by Austin Tooley on 8/19/17.
//  Copyright © 2017 Austin Tooley. All rights reserved.
//

import Foundation
import MapKit

extension MKMapView {
    
    func centerMapOnLocation(location: Location, radius: CLLocationDistance)
    {
        let clLocation = CLLocation(latitude: location.lat, longitude: location.long)
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(clLocation.coordinate, radius * 2.0, radius * 2.0)
        self.setRegion(coordinateRegion, animated: true)
    }
}
