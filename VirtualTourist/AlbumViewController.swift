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
    @IBOutlet weak var infoLabel: UILabel!
    
    var location: Location?
    let radius = 200
    let flickr = FlickrManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureInfoLabel()
        
       
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        // Make sure we have a location
        if let location = location {
            print("Location \(location)")
            
            // Configure map
            setUpMap(location: location)
            
            // flickr
            flickr.searchByLocation(location: location) { (result, error) in
                if let error = error {
                    self.displayMessage(error: error)
                } else {
                    print("yay")
                }
            }
                
        }
    }
    
    func configureInfoLabel() {
        infoLabel.layer.borderColor = UIColor(red: 33/255, green: 160/255, blue: 160/255, alpha: 1).cgColor
        infoLabel.layer.borderWidth = 2.0
        infoLabel.layer.cornerRadius = 6
        infoLabel.layer.masksToBounds = true
        infoLabel.text = ""
        infoLabel.isHidden = true
    }
    
    func displayMessage(error: Error) {
        performUIUpdatesOnMain {
            self.infoLabel.isHidden = false
            self.infoLabel.text = error.localizedDescription
        }
    }
    
    // MARK: Map
    func setUpMap(location: Location) {
        
        let regionRadius: CLLocationDistance = 2000
        
            // Center map on location
            self.mapView.centerMapOnLocation(location: location, radius: regionRadius)
        
            // Place pin
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: location.lat, longitude: location.long)
            self.mapView.addAnnotation(annotation)
    }
    
    // MARK: Collection View
    
    // MARK: Network
    
}
