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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureMap()
        
        // Get locations
        getLocationsFromDB()
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
        longPressRecognizer.minimumPressDuration = 0.7
        
        map.addGestureRecognizer(longPressRecognizer)
    }

    // Add pin to map from gesture coords
    func addPin(gestureRecognizer:UIGestureRecognizer) {
        
        // So holding and dragging doesn't lay down a bazillion pins
        if gestureRecognizer.state == UIGestureRecognizerState.began {
            // Get coords
            let touchPoint = gestureRecognizer.location(in: map)
            let newCoordinates = map.convert(touchPoint, toCoordinateFrom: map)
            let annotation = MKPointAnnotation()
            
            // Add to map
            annotation.coordinate = newCoordinates
            map.addAnnotation(annotation)
            
            // Add to db
            let location = Location(context: CoreDataStack.shared.context)
            location.lat = Double(newCoordinates.latitude)
            location.long = Double(newCoordinates.longitude)
            CoreDataStack.shared.save()
        }
    }
    
    // Handle tap on existing pin
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView)
    {
        // Get location
        if let annotation = view.annotation {
            var location: Location!
            let lat = Double(annotation.coordinate.latitude)
            let long = Double(annotation.coordinate.longitude)
            
            // Get location
            do {
                let fr = NSFetchRequest<Location>(entityName: "Location")
                let predicate = NSPredicate(format: "lat == %@ AND long == %@", argumentArray: [lat, long])
                fr.predicate = predicate
                let locations = try CoreDataStack.shared.context.fetch(fr)
                if let foundLocation = locations.first {
                    location = foundLocation
                }
            } catch let error as NSError {
                print("Failed to get location: \(error.localizedDescription)")
            }
            
            // Deselect pin
            mapView.deselectAnnotation(annotation, animated: false)
            
            // Push the album view
            if let controller = self.storyboard!.instantiateViewController(withIdentifier: "albumVC") as? AlbumViewController {
                controller.location = location
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
            let results = try CoreDataStack.shared.context.fetch(fr)
            if let results = results as? [Location] {
                locations = results
                print("Locations: \(locations.count)")
            }
        } catch {
            print("No locations")
        }
    
        // Add locations to map
        for (_,location) in locations.enumerated() {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(location.lat),
                                                           longitude: CLLocationDegrees(location.long))
            annotations.append(annotation)
        }
        map.addAnnotations(annotations)
    }
}

