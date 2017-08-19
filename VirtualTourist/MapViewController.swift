//
//  ViewController.swift
//  VirtualTourist
//
//  Created by Austin Tooley on 8/5/17.
//  Copyright © 2017 Austin Tooley. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var map: MKMapView!
    private let pinIdentifier = "pinID"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureMap()
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
        let touchPoint = gestureRecognizer.location(in: map)
        let newCoordinates = map.convert(touchPoint, toCoordinateFrom: map)
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoordinates
        map.addAnnotation(annotation)
    }
    
    // Handle tap on existing pin
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView)
    {
        // get location
        if let annotation = view.annotation {
            let location = Location(lat: Double(annotation.coordinate.latitude), long: Double(annotation.coordinate.longitude))
            
            // push the album view
            if let controller = self.storyboard!.instantiateViewController(withIdentifier: "albumVC") as? AlbumViewController {
                controller.location = location
                navigationController!.pushViewController(controller, animated: true)
            }
        }
    }
}

