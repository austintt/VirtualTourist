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
    var selectedPhotos = [NSIndexPath]()
    {
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
                print("Photos from db: \(photos.count)")
            } else {
                searchPhotos()
            }
            
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
    
    // MARK: Network & DB
    
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
                print(result)
                return result.count > 0 ? result : nil
            }
        } catch {
            print("Error getting photos from DB")
        }
        
        return nil
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
        let pic = self.photos[indexPath.row] as! Photo
        
        // If there is not pic in Core data, issue the download.
        if pic.image == nil {
            cell.activityIndicator.startAnimating()
            
            //Download photos from Flickr API.
            flickr.downloadPhotos(photoURL: pic.url!){ (image, error)  in
                
                //Check if the image data is not nil
                guard let imageData = image,
                    let downloadedImage = UIImage(data: imageData as Data) else {
                    return
                }
                
                performUIUpdatesOnMain {
                        pic.image = imageData
                        CoreDataStack.shared.save()
                        
                        if let updateCell = self.collectionView.cellForItem(at: indexPath) as? PhotoCell {
                            updateCell.imageView.image = downloadedImage
                            updateCell.activityIndicator.stopAnimating()
                        }
                }
                cell.imageView.image = UIImage(data: imageData as Data)
                self.configureCellSection(cell: cell, indexPath: indexPath as NSIndexPath)
            }
        } else {
            // Display the image loaded from Core data.
            cell.imageView.image = UIImage(data: pic.image as! Data)
        }
        return cell
    }
    
    // When image is tapped
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath as IndexPath) as! PhotoCell
        
        if let index = selectedPhotos.index(of: indexPath as NSIndexPath) {
            selectedPhotos.remove(at: index)
        } else {
            selectedPhotos.append(indexPath as NSIndexPath)
        }
        configureCellSection(cell: cell, indexPath: indexPath as NSIndexPath)
    }
    
    func configureCellSection(cell: PhotoCell, indexPath: NSIndexPath) {
        if let _ = selectedPhotos.index(of: indexPath) {
            cell.alpha = 0.5
        } else {
            cell.alpha = 1.0
        }
    }
}
