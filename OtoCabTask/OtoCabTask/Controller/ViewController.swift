//
//  ViewController.swift
//  OtoCabTask
//
//  Created by Gado on 5/7/20.
//  Copyright © 2020 Gado. All rights reserved.
//

import UIKit
import GoogleMaps
import Alamofire
import SwiftyJSON

class ViewController: UIViewController {
    
    // MARK:- Outlets
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var addressLabel: UILabel!
    
    
    // MARK:- Properties
    
    private let locationManager = CLLocationManager()
    
    var destinations = [Pin?]()
    
    // MARK:- Override Functions
    // viewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    // MARK:- Actions
    
    // MARK:- Methods
    
    func configureView() {
        
        // User Location
        locationManager.delegate = self as? CLLocationManagerDelegate
        mapView.delegate = self as? GMSMapViewDelegate
        locationManager.requestWhenInUseAuthorization()
        mapView.settings.myLocationButton = true
        
        mapView.isMyLocationEnabled = true
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Make Route", style: .plain, target: self, action: #selector(makeRoute))
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        let alert = UIAlertController(title: "Attention!", message: "It's recommended you putting two pins to can make a route.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        self.present(alert, animated: true)
    }
    
    private func reverseGeocodeCoordinate(_ coordinate: CLLocationCoordinate2D) {
        
        let geocoder = GMSGeocoder()
        geocoder.reverseGeocodeCoordinate(coordinate) { response, error in
            guard let address = response?.firstResult(), let lines = address.lines else {
                return
            }
            self.addressLabel.text = lines.joined(separator: "\n")
            
            UIView.animate(withDuration: 0.25) {
                
                self.view.layoutIfNeeded()
            }
        }
    }
    
    
    @objc func makeRoute() {
        
        guard let  firstDestinations = destinations[0] else {
            return
        }
        
        guard let  secondDestinations = destinations[1] else {
            return
        }
        
        setMapCamera(pin: firstDestinations)
        setMapCamera(pin: secondDestinations)
        // draw()
        drawPath()
    }
    
    private func setMapCamera(pin :Pin) {
        CATransaction.begin()
        CATransaction.setValue(2, forKey: kCATransactionAnimationDuration)
        mapView?.animate(to: GMSCameraPosition.camera(withTarget: pin.location, zoom: pin.zoom))
        CATransaction.commit()
        
        let marker = GMSMarker(position: pin.location)
        marker.title = pin.name
        marker.map = mapView
    }
    
    //    func draw() {
    //        let path = GMSMutablePath()
    //        path.addLatitude(destinations[0]!.location.latitude, longitude:destinations[0]!.location.longitude)
    //        path.addLatitude(destinations[1]!.location.latitude, longitude:destinations[1]!.location.longitude)
    //
    //        let polyline = GMSPolyline(path: path)
    //        polyline.strokeColor = .red
    //        polyline.strokeWidth = 3.0
    //        polyline.map = self.mapView
    //
    //    }
    
    
    
    // MARK:- TAKE CARE
    
    // 1- Note: The Google Places API Web Service does not work with an Android or iOS restricted API key.
    // 2- ERROR : This IP, site or mobile application is not authorized to use this API key

        /*
     Choose key
     API Restriction tab
     Choose API key
     Save
     Choose Application Restriction -> None
     Save
     
     3- You must enable Billing on the Google Cloud Project
     */
     
    func drawPath()
    {
        //           let origin = "\(43.1561681),\(-75.8449946)"
        //           let destination = "\(38.8950712),\(-77.0362758)"
        
        let origin = "\(destinations[0]!.location.latitude),\(destinations[0]!.location.longitude)"
        let destination = "\(destinations[1]!.location.latitude),\(destinations[1]!.location.longitude)"
        
        
        let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=driving&key="
        
        
        
        AF.request(url).responseJSON { response in
            
            guard let data = response.data else
            {
                return
            }
            print(response.request ?? "")  // original URL request
            print(response.response ?? "") // HTTP URL response
            print(data)     // server data
            print(response.result)   // result of response serialization
            
            do {
                let jsonData = try JSON(data: data)
                let routes = jsonData["routes"].arrayValue
                
                for route in routes
                {
                    let routeOverviewPolyline = route["overview_polyline"].dictionary
                    let points = routeOverviewPolyline?["points"]?.stringValue
                    let path = GMSPath.init(fromEncodedPath: points!)
                    let polyline = GMSPolyline.init(path: path)
                    polyline.strokeColor = .red
                    polyline.strokeWidth = 5.0
                    polyline.map = self.mapView
                }
            }
            catch {
                print("ERROR: not working")
            }
            
        }
    }
}


// MARK: - CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        guard status == .authorizedWhenInUse else {
            return
        }
        locationManager.startUpdatingLocation()
        
        mapView.isMyLocationEnabled = true
        mapView.settings.myLocationButton = true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            return
        }
        
        mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 20, bearing: 0, viewingAngle: 0)
        
        locationManager.stopUpdatingLocation()
    }
}

// MARK: - GMSMapViewDelegate
extension ViewController: GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        reverseGeocodeCoordinate(position.target)
    }
    
    // Make pin by Tap
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D){
        print("You tapped at \(coordinate.latitude), \(coordinate.longitude)")
        
        if destinations.count == 2 {
            navigationItem.rightBarButtonItem?.isEnabled = false
            destinations.removeAll()
            mapView.clear() // clearing Pin before adding new
        } else if destinations.count == 1 {
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
        
        let marker = GMSMarker(position: coordinate)
        destinations.append(Pin(name: "", location: CLLocationCoordinate2DMake(coordinate.latitude,coordinate.longitude), zoom: 10))
        marker.map = mapView
    }
    
}


