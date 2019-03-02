//
//  ViewController.swift
//  XMap
//
//  Created by Michael Cheng on 21/05/2017.
//  Copyright © 2017 Michael Cheng. All rights reserved.
//
import Foundation
import ObjectMapper
import UIKit
import GoogleMaps
import GooglePlacesAPI
import GoogleMapsDirections
import Alamofire

import ObjectMapper

class ViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {

    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var arrivalLabel: UILabel!
    @IBOutlet weak var speedLabel: UILabel!
    @IBOutlet weak var mapView: GMSMapView!
    
    var locationManager:CLLocationManager!
    var isGettingLocation = false
    var panoView: GMSPanoramaView!
    var currentHeading: CLLocationDirection!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //getCurrentLocation()
        panoView = GMSPanoramaView(frame: .zero)
        
        
        addPanoPoints(moveCamera: true, encodedString: "augcFlryfV~BuBh@c@f@c@")
        addPanoPoints(moveCamera: false, encodedString: "ongcFnlyfV^f@h@l@FJp@dAj@|@x@tAf@v@LRHPNZJVFNLb@FRL\\z@fBNTDFHN|AjCd@r@|@vAZf@d@v@^l@R\\Vb@\\f@xA`C`A|AdAbBZf@Xf@lAnB`@l@RVZ^x@z@TRlBjBlAbAPPRTNP^^rApAzBtBr@r@jBfBr@n@DFZZZd@T^JPFNHRZ`AF^Ff@Fb@Bd@Bt@@bC?~@?`@B`@Fn@Fd@XpAFN")
        getCurrentHeading()
        self.view = panoView

    }

    
    func getCurrentHeading (){
        print("To get current heading")
        let status = CLLocationManager.authorizationStatus()
        if locationManager == nil {
            locationManager = CLLocationManager()
            locationManager.delegate = self
        }
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        isGettingLocation = true
        locationManager.startUpdatingHeading()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.currentHeading = newHeading.trueHeading
        debugPrint("Current heading is \(currentHeading)")
        self.locationManager.stopUpdatingHeading()
        self.panoView.camera = GMSPanoramaCamera(heading: currentHeading.magnitude, pitch: 0, zoom: 1)
    }
    

    func getCurrentLocation (){
        print("To get current location")
        let status = CLLocationManager.authorizationStatus()
        if locationManager == nil {
            locationManager = CLLocationManager()
            locationManager.delegate = self
        }
        if status == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        isGettingLocation = true
        locationManager.requestLocation()
        print("GPS locate okay?")
    }
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if isGettingLocation {
            isGettingLocation = false
            print("GPS locate okay!")
            debugPrint(locations)
            let location = locations.first!
            //clear previous markers and add new ones
            mapView.clear()
            
            let camera = GMSCameraPosition.camera(withTarget: location.coordinate, zoom: 17.0)
            mapView.isMyLocationEnabled = true
            self.mapView.animate(to: camera)
            
            //Finally stop updating location otherwise it will come again and again in this delegate
            //let originMarker = GMSMarker(position: location.coordinate)
            //originMarker.icon = UIImage.init(named: "origin_16.png")
            //originMarker.map = mapView
            
            //street view web api
            //https://maps.googleapis.com/maps/api/streetview?size=400x400&location=40.720032,-73.988354&fov=90&heading=235&pitch=10&key=AIzaSyC0OYHHABlRzcXHgwSXVa7XC_AKMznGQEg
            
            GoogleMapsDirections.provide(apiKey: "AIzaSyC0OYHHABlRzcXHgwSXVa7XC_AKMznGQEg")
            let origin = GoogleMapsDirections.Place.coordinate(coordinate: GoogleMapsDirections.LocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
            let destination = GoogleMapsDirections.Place.stringDescription(address: "san francisco, usa")
            // You can also use coordinates or placeID for a place
            // let origin = Place.Coordinate(coordinate: LocationCoordinate2D(latitude: 43.4697354, longitude: -80.5397377))
            // let origin = Place.PlaceID(id: "ChIJb9sw59k0K4gRZZlYrnOomfc")
            GoogleMapsDirections.direction(fromOrigin: origin, toDestination: destination) { (response, error) -> Void in
                // Check Status Code
                guard response?.status == GoogleMapsDirections.StatusCode.ok else {
                    // Status Code is Not OK
                    debugPrint(response?.errorMessage)
                    return
                }
                
                //http://techqa.info/programming/question/28784034/swift-ios-google-map,-path-to-coordinate
                // Use .result or .geocodedWaypoints to access response details
                // response will have same structure as what Google Maps Directions API returns
                debugPrint("it has \(response?.routes.count ?? 0) routes")
                guard let routesArray = response?.routes.toJSON() else{
                    print ("no route available")
                    return
                }
                let routes = (routesArray.first)!
                debugPrint("The route is \(routes)")
                
                //https://roads.googleapis.com/v1/snapToRoads?path=-35.27801,149.12958|-35.28032,149.12907|-35.28099,149.12929|-35.28144,149.12984|-35.28194,149.13003|-35.28282,149.12956|-35.28302,149.12881|-35.28473,149.12836&interpolate=true&key=YOUR_API_KEY
                
//                baseRequestParameters + [
//                    "origin" : origin.toString(),
//                    "destination" : destination.toString(),
//                    "mode" : travelMode.rawValue.lowercased()
//                
                
                
                //Snip to road isnt required for short distance
                //let baseURLString = "https://roads.googleapis.com/v1/snapToRoads?path="
                //let request = Alamofire.request(baseURLString, parameters: routes).responseJSON{response in}
                let overviewPolyline = (routes["overview_polyline"] as? Dictionary<String,AnyObject>) ?? [:]
                let polypoints = (overviewPolyline["points"] as? String) ?? ""
                let line  = polypoints
                self.addPolyLine(encodedString: line)
            }
            
        }else{
            print ("Location has already been acquired")
        }
    }
    
    func addPanoPoints(moveCamera: Bool, encodedString: String) {
        let temp: [CLLocationCoordinate2D]? = decodePolyline(encodedString)
        guard let coordinates = temp else{
            print ("decode polyline unsuccessful")
            return
        }
        let tenXCoords = addTenXPoints(originalCoords: coordinates)
        // Create a marker at the Eiffel Tower
        
        if moveCamera {
            if coordinates.count > 2 {
                
                panoView.moveNearCoordinate((coordinates[coordinates.count-2]))
            }else {
                panoView.moveNearCoordinate((coordinates.last)!)
            }
        }
        let _ = tenXCoords.map {
            let marker = GMSMarker(position: ($0))
            // Add the marker to a GMSMapView object named mapView
            // Add the marker to a GMSPanoramaView object named panoView
            marker.panoramaView = panoView
        }
        
    }
    
    
    func addTenXPoints(originalCoords: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        var tenXCoords: [CLLocationCoordinate2D]! = []
        for index in 0..<(originalCoords.count - 1){
            tenXCoords.append(originalCoords[index])
            let orgLat = originalCoords[index].latitude 
            let orgLog = originalCoords[index].longitude 
            let orgNxtLat = originalCoords[index + 1].latitude
            let orgNxtLog = originalCoords[index + 1].longitude
            let maxItr = 10
            for itr in 1...(maxItr-1){
                let iLat = ( Double(itr) * orgLat + Double((maxItr - itr)) * orgNxtLat) / Double(maxItr)
                let iLog = ( Double(itr) * orgLog + Double((maxItr - itr)) * orgNxtLog) / Double(maxItr)
                let iCoord = CLLocationCoordinate2D(latitude: iLat, longitude: iLog)
                tenXCoords.append(iCoord)
            }
        }
        tenXCoords.append(originalCoords[(originalCoords.count - 1)])
        return tenXCoords
    }
    
    
    func addPolyLine(encodedString: String) {        
        let path = GMSMutablePath(fromEncodedPath: encodedString)
        let polyline = GMSPolyline(path: path)
        polyline.strokeWidth = 5
        polyline.strokeColor = .blue
        polyline.map = self.mapView
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        isGettingLocation = false
        print ("GPS error")
        let okAction = UIAlertAction(title: "OK", style: .default) { (action) in}
        let gpsAlert = UIAlertController(title: "Error", message: "GPS error", preferredStyle: .alert)
        gpsAlert.addAction(okAction)
        self.present(gpsAlert, animated: true, completion: nil)
    }
}

