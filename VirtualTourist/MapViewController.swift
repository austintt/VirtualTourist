//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Austin Tooley on 8/5/17.
//  Copyright © 2017 Austin Tooley. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var map: MKMapView!
    
    private let pinIdentifier = "pinID"
    let dataManager = CoreDataManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureMap()
        
        // Get locations
        getLocationsFromDB()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: Map
    func configureMap() {
        map.delegate = self
        addLongPressRecognizer()
    }
    
    // Recognize long press to add pin
    func addLongPressRecognizer() {
        // [Long Press Recognizer](https://stackoverflow.com/questions/30858360/adding-a-pin-annotation-to-a-map-view-on-a-long-press-in-swift)
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addPin))
        longPressRecognizer.minimumPressDuration = 1.0
        
        map.addGestureRecognizer(longPressRecognizer)
    }

    // Add pin to map from gesture coords
    func addPin(gestureRecognizer:UIGestureRecognizer){
        
        // Get coords
        let touchPoint = gestureRecognizer.location(in: map)
        let newCoordinates = map.convert(touchPoint, toCoordinateFrom: map)
        let annotation = MKPointAnnotation()
        
        // Add to map
        annotation.coordinate = newCoordinates
        map.addAnnotation(annotation)
        
        // Add to db
        let location = Location(lat: Double(newCoordinates.latitude), long: Double(newCoordinates.longitude), context: dataManager.context)
    }
    
    // Handle tap on existing pin
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView)
    {
        // get location
        if let annotation = view.annotation {
            //let location = Location(lat: Double(annotation.coordinate.latitude), long: Double(annotation.coordinate.longitude))
            
            // push the album view
            if let controller = self.storyboard!.instantiateViewController(withIdentifier: "albumVC") as? AlbumViewController {
                //controller.location = location
                navigationController!.pushViewController(controller, animated: true)
            }
        }
    }
    
    // MARK: Core Data
    func getLocationsFromDB() {
        
        var locations = [Location]()
        var annotations = [MKAnnotation]()
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        
        // Get the locations
        do {
            let results = try dataManager.context.fetch(fr)
            if let results = results as? [Location] {
                locations = results
                print("Locations: \(locations.count)")
            }
        } catch {
            print("No locations")
        }
    
        // Add locations to map
//        for location in locations.enumerated() {
//            let annotation = MKPointAnnotation()
//            annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(location.latitude),
//                                                           longitude: CLLocationDegrees(location.longitude))
//            annotations.append(annotation)
//        }
//        mapView.addAnnotations(annotations)
    }
}

