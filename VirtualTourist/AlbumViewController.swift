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

class AlbumViewController: UIViewController, NSFetchedResultsControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var actionButton: UIButton!
    
    var location: Location?
    let radius = 200
    var photos = [Photo]()
    let flickr = FlickrManager()
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>!
    
    // Set button title
    var selectedPhotos = [Photo]()
    {
        // Change button title based on whether or not photos are selected
        didSet
        {
            actionButton.titleLabel?.text = selectedPhotos.isEmpty ? "New Collection" : "Delete Photos"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        configureInfoLabel()
        
        // Make sure we have a location
        if let location = location {
            print("Location \(location)")
            
            // Search or fetch photos
            if let dbResult = getPhotosFromDB() {
                photos = dbResult
                performUIUpdatesOnMain {
                    self.collectionView.reloadData()
                }
                print("Photos from db: \(photos.count)")
            } else {
                searchPhotos()
                print("Photos from search: \(self.photos.count)")
            }
            
            // Configure map
            setUpMap(location: location)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
    }
    
    func configureInfoLabel() {
        infoLabel.layer.borderWidth = 0.0
        infoLabel.layer.cornerRadius = 6
        infoLabel.layer.masksToBounds = true
        infoLabel.text = ""
        infoLabel.isHidden = true
    }
    
    func displayMessage(text: String) {
        performUIUpdatesOnMain {
            self.infoLabel.isHidden = false
            self.infoLabel.text = text
        }
    }
    
    // MARK: Map
    func setUpMap(location: Location) {
        
        let regionRadius: CLLocationDistance = 4000
        
            // Center map on location
            self.mapView.centerMapOnLocation(location: location, radius: regionRadius)
        
            // Place pin
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: location.lat, longitude: location.long)
            self.mapView.addAnnotation(annotation)
    }
    
    // MARK: Network & DB
    
    func searchPhotos() {
        if let location = self.location {
            flickr.searchByLocation(location: location) { (result, error) in
                if let error = error {
                    self.displayMessage(text: error.localizedDescription)
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
                        performUIUpdatesOnMain {
                            self.collectionView.reloadData()
                        }
                        
                        CoreDataStack.shared.save()
                        print("Found photos: \(urls.count)")
                        print("photos: \(self.photos.count)")
                    }
                }
            }
        }
    }
    
    func getPhotosFromDB() -> [Photo]? {
        // Get all photos related to this location
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        let predicate = NSPredicate(format: "location == %@", argumentArray: [location!])
        fr.predicate = predicate
        
        do {
            if let result = try CoreDataStack.shared.context.fetch(fr) as? [Photo] {
                if result.count > 0 {
                    return result
                } else {
                    displayMessage(text: "No photos at location")
                }
            }
        } catch {
            displayMessage(text: "Error getting photos from DB")
        }
        
        return nil
    }
    
    private func deleteAllLocationPhotos() {
        // Delete from db
        for photo in photos {
            CoreDataStack.shared.context.delete(photo)
        }
        // Reset arrays, save
        photos.removeAll()
        selectedPhotos = [Photo]()
        collectionView.reloadData()
        CoreDataStack.shared.save()
    }
    
    private func deleteSelectedPhotos() {
        for photo in selectedPhotos {
            // Remove from photos array
            photos.remove(at: photos.index(of: photo)!)
            
            // Delete from db
            CoreDataStack.shared.context.delete(photo)
        }
        
        // Save and empty selectedPhotos, refresh view
        CoreDataStack.shared.save()
        selectedPhotos = [Photo]()
        collectionView.reloadData()
    }
    
    // MARK: Collection View
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //Get the Collection Cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        
        //Get the Photo Image saved in the DB.
        let photo = self.photos[indexPath.row] as! Photo
        
        // If no image in db, download.
        if photo.image == nil {
            cell.activityIndicator.startAnimating()
            
            // Download photos from Flickr API.
            flickr.downloadPhotos(photoURL: photo.url!){ (image, error)  in
                
                //Check if the image data is not nil
                guard let imageData = image,
                    let downloadedImage = UIImage(data: imageData as Data) else {
                    return
                }
                
                // Save data
                photo.image = imageData
                CoreDataStack.shared.save()
                
                // Display images
                performUIUpdatesOnMain {
                    if let updateCell = self.collectionView.cellForItem(at: indexPath) as? PhotoCell {
                        updateCell.imageView.image = downloadedImage
                        updateCell.activityIndicator.stopAnimating()
                    }
                }
                cell.imageView.image = UIImage(data: imageData as Data)
            }
        } else {
            // Display the image loaded from Core data.
            cell.imageView.image = UIImage(data: photo.image as! Data)
        }
        return cell
    }
    
    @IBAction func actionButtonPressed(_ sender: Any) {
        infoLabel.isHidden = true
        
        // Check if we have any selected photos
        if selectedPhotos.isEmpty {
            // Clear all photos and request new
            deleteAllLocationPhotos()
            searchPhotos()
            
        } else {
            // Delete selected photos
            deleteSelectedPhotos()
        }
    }
    
    // Handle tap on image
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath as IndexPath) as! PhotoCell
        let photo = photos[indexPath.row]
        
        // Unmark selected image
        if selectedPhotos.contains(photo) {
            cell.alpha = 1.0
            selectedPhotos.remove(at: selectedPhotos.index(of: photo)!)
        // Mark selected image
        } else {
            cell.alpha = 0.5
            selectedPhotos.append(photo)
        }
    }
}
