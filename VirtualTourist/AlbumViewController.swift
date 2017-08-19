//
//  AlbumViewController.swift
//  VirtualTourist
//
//  Created by Austin Tooley on 8/19/17.
//  Copyright © 2017 Austin Tooley. All rights reserved.
//

import UIKit
import MapKit

class AlbumViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var location: Location?
    let radius = 200
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        // Make sure we have a location
        if let location = location {
            print("Location \(location)")
            
            // Configure map
            setUpMap(location: location)
        }
    }
    
    
    
    func setUpMap(location: Location) {
        
        let regionRadius: CLLocationDistance = 2000
//        performUIUpdatesOnMain {
            // Center map on location
            self.mapView.centerMapOnLocation(location: location, radius: regionRadius)
        
            // Place pin
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: location.lat, longitude: location.long)
            self.mapView.addAnnotation(annotation)
//        }
    }
    
}
