//
//  FlickrManager.swift
//  VirtualTourist
//
//  Created by Austin Tooley on 8/19/17.
//  Copyright © 2017 Austin Tooley. All rights reserved.
//

import Foundation

class FlickrManager: NSObject {
    
    // MARK: Initializer
    var session = URLSession.shared

    // MARK: API
    func searchByLocation(location: Location, completionHandlerForSearchByLocation: @escaping (_ result: [String]?, _ error: NSError?) -> Void) {
        
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(location: location),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.PerPage: Constants.FlickrParameterValues.PhotosPerPage,
            Constants.FlickrParameterKeys.Page: "\(arc4random_uniform(10) + 1)",
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
        ]
        
        getPhotos(methodParameters as [String : AnyObject]) { (results, error) in
            if let error = error {
                completionHandlerForSearchByLocation(nil, error)
            } else {
                completionHandlerForSearchByLocation(results, nil)
            }
        }
    }
    
    private func bboxString(location: Location?) -> String {
        // ensure bbox is bounded by minimum and maximums
        if let location = location {
            let latitude = location.lat
            let longitude = location.long
            let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
            let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
            let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
            let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
            return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
        } else {
            return "0,0,0,0"
        }
    }
    
    private func getPhotos(_ methodParameters: [String: AnyObject], completionHandlerForGetPhotos: @escaping (_ result: [String]?, _ error: NSError?) -> Void) {
        // create session and request
        let request = URLRequest(url: flickrURLFromParameters(methodParameters))
        
        // create network request
        let task = session.dataTask(with: request) { (data, response, error) in
            
            // if an error occurs, print it and re-enable the UI
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGetPhotos(nil, NSError(domain: "getPhotos", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:AnyObject]
            } catch {
                sendError("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else {
                sendError("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                sendError("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] else {
                sendError("Cannot find keys '\(Constants.FlickrResponseKeys.Photo)' in \(parsedResult)")
                return
            }
            
            // Get URLs of photos
            var photoURLS = [String]()
            for photo in photosArray {
                if let photoURL = photo[Constants.FlickrResponseKeys.MediumURL] as? String {
                    photoURLS.append(photoURL)
                }
            }
        
            completionHandlerForGetPhotos(photoURLS, nil)
        }
        
        // start the task!
        task.resume()
    }
    
    private func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    //Download photos based on the provided photo URL.
    func downloadPhotos(photoURL: String, completionHandlerForDownloadPhotos: @escaping (_ image: NSData?, _ error: NSError?) -> Void)
    {
        let url = NSURL(string: photoURL)
        let request = URLRequest(url: url! as URL)
        
        let task = session.dataTask(with: request){ data, response, error in
            
            guard let data = data else
            {
                let userInfo = [NSLocalizedDescriptionKey : "Not able to download photo"]
                completionHandlerForDownloadPhotos(nil, NSError(domain: "downloadPhotos", code: 1, userInfo: userInfo))
                return
            }
            completionHandlerForDownloadPhotos(data as NSData, nil)
        }
        task.resume()
    }
}
