//
//  ViewController.swift
//  BottomMenuExample
//
//  Created by Руслан Кукса on 1/6/19.
//  Copyright © 2019 Ruslan Kuksa. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {
    
    @IBOutlet weak var markerImage: UIImageView!
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var adressLabel: UILabel!
    @IBOutlet weak var goButton: UIButton!
    @IBOutlet weak var stackView: UIView!
    
    
    var locationManager = CLLocationManager()
    let regionInMeters: Double = 3000
    let annotation = MKPointAnnotation()
    var directionsArray = [MKDirections]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        markerImage.isHidden = true
        //stackView.isHidden = true
        
        goButton.layer.cornerRadius = 20
        stackView.layer.cornerRadius = 20
        adressLabel.sizeToFit()
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action:(#selector(ViewController.userPickLocation)))
        //longPressGesture.delegate = (self as! UIGestureRecognizerDelegate)
        mapView.addGestureRecognizer(longPressGesture)
        
        checkLocationServices()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        stackView.alpha = 0
        stackView.isHidden = false
        
    }
    
    // MARK: - Check locations services access
    
    func locationManagerSetup() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            locationManagerSetup()
            checkLocationAuthorization()
        } else {
            
        }
    }
    
    func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            trackingUserLocation()
        case .authorizedAlways:
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied:
            break
        case .restricted:
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    
    // MARK: - Start tracking user location
    
    func trackingUserLocation() {
        mapView.showsUserLocation = true
        setCenterUserLocation()
        locationManager.startUpdatingLocation()
    }
    
    func setCenterUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    
    // MARK: - Create direction from user location to annotation:
    
    func getDirection() {
        guard let location = locationManager.location?.coordinate else { return }
        
        let request = makeDirectionRequest(from: location)
        let directions = MKDirections(request: request)
        resetMapView(with: directions)
        
        
        directions.calculate { (response, error) in
            guard let response = response else { return }
            
            for route in response.routes {
                self.mapView.addOverlay(route.polyline)
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }
        }
        
    }
    
    func makeDirectionRequest(from coordinates: CLLocationCoordinate2D) -> MKDirections.Request {
        let destinationCoords = annotation.coordinate
        let startLocation = MKPlacemark(coordinate: coordinates)
        let destinationLocation = MKPlacemark(coordinate: destinationCoords)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startLocation)
        request.destination = MKMapItem(placemark: destinationLocation)
        request.transportType = .walking
        request.requestsAlternateRoutes = true
        
        return request
    }
    
    
    func resetMapView(with directions: MKDirections) {
        mapView.removeOverlays(mapView.overlays)
        directionsArray.append(directions)
        _ = directionsArray.map { $0.cancel() }
        directionsArray.removeAll()
    }

    
    @IBAction func goButtonPressed(_ sender: UIButton) {
        getDirection()
    }
    
    
    // MARK: - Create annotation on the map and get data from it
    
    @objc func userPickLocation(gestureRecognizer: UILongPressGestureRecognizer) {
        
        let location = gestureRecognizer.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        annotation.coordinate = coordinate
        
        mapView.addAnnotation(annotation)
        mapView.selectAnnotation(annotation, animated: true)
        
        guard let distance = (locationManager.location?.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude))) else { return }
        let distanceInKilometers = (distance / 1000)
        
        let geoCoder = CLGeocoder()
        
        geoCoder.cancelGeocode()
        
        geoCoder.reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) { (placemark, error) in
            
            if let _ = error {
                print(error as Any)
            }
            
            guard let placemark = placemark?.first else { return }
            
            let streetName = placemark.thoroughfare ?? "Unknown"
            let streetNumber = placemark.subThoroughfare ?? ""
            let cityName = placemark.locality ?? "Unknown"
            let countryName = placemark.country ?? "Unknown"
            let distanceBetween = String(format: "%.2f", distanceInKilometers)
            
            DispatchQueue.main.async {
                self.distanceLabel.text = "\(distanceBetween) km"
                self.adressLabel.text = "Adress:\n\(streetName) \(streetNumber)\n\(cityName), \(countryName)"
            }
        }
        
        //stackView.isHidden = false
        showUpBottomMenu()
    
    }
    
    func showUpBottomMenu() {
        UIView.animate(withDuration: 0.3) {
            self.stackView.alpha = 1
        }
    }
    
}



extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}


extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let render = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        render.strokeColor = .blue
        
        return render
    }
}
