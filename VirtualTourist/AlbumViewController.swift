//
//  AlbumViewController.swift
//  VirtualTourist
//
//  Created by Austin Tooley on 8/19/17.
//  Copyright © 2017 Austin Tooley. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class AlbumViewController: UIViewController, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var infoLabel: UILabel!
    
    var location: Location?
    let radius = 200
    var photos = [Photo]()
    let flickr = FlickrManager()
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make sure we have a location
        if let location = location {
            print("Location \(location)")
            
            // Search or fetch photos
            if let dbResult = getPhotosFromDB() {
                photos = dbResult
                print("Photos from db: \(photos.count)")
            } else {
                searchPhotos()
            }
            
            configureInfoLabel()
            
            // Configure map
            setUpMap(location: location)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
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
    
    func searchPhotos() {
        if let location = self.location {
            flickr.searchByLocation(location: location) { (result, error) in
                if let error = error {
                    self.displayMessage(error: error)
                } else {
                    
                    // Save photos to DB
                    if let urls = result {
                        
                        // for each photo we found, make a new Photo object
                        for url in urls {
                            let photo = Photo(context: CoreDataStack.shared.context)
                            photo.url = url
                            photo.location = self.location
                            
                            self.photos.append(photo)
                        }
                        
                        CoreDataStack.shared.save()
                        print("Found photos: \(urls.count)")
                        print("photos: \(self.photos.count)")
                    }
                }
            }
        }
    }
    
    // MARK: DB
    
    func getPhotosFromDB() -> [Photo]? {
        // Get all photos related to this location
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        let predicate = NSPredicate(format: "location == %@", argumentArray: [location!])
        fr.predicate = predicate
        
        do {
            if let result = try CoreDataStack.shared.context.fetch(fr) as? [Photo] {
                print(result)
                return result.count > 0 ? result : nil
            }
        } catch {
            print("Error getting photos from DB")
        }
        
        return nil
    }
    
}
