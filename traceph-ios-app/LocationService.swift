//
//  LocationService.swift
//  traceph-ios-app
//
//  Created by Enzo on 30/03/2020.
//  Copyright © 2020 traceph. All rights reserved.
//

import CoreLocation

// REVIEW: Maybe convert this into a struct
// timestamp may be useful to differentiate with bluetooth timestamp to indicate accuracy of location
typealias SimpleCoordinates = (lon: Double, lat: Double, timestamp: Double)

class LocationService: NSObject {
    var currentCoords: SimpleCoordinates = (lon: Double.nan, lat: Double.nan, timestamp: Double.nan)
    
    lazy var locationManager:CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        manager.distanceFilter = 10
        manager.pausesLocationUpdatesAutomatically = true
        return manager
    }()
    
    func requestPermissions() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways:
            manager.startUpdatingLocation()
            
        case .authorizedWhenInUse:
            manager.startUpdatingLocation()
            
        case .denied:
            print("location auth denied")
        
        case .notDetermined:
            print("location auth not determined")
            
        case .restricted:
            print("location auth restricted")
            
        default:
            print("location auth error")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinates: CLLocationCoordinate2D = locations.last?.coordinate else { return }
        currentCoords.lat = coordinates.latitude
        currentCoords.lon = coordinates.longitude
        currentCoords.timestamp = Date().timeIntervalSince1970
    }
}
