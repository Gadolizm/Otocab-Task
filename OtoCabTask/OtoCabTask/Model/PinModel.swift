//
//  PinModel.swift
//  OtoCabTask
//
//  Created by Gado on 5/8/20.
//  Copyright © 2020 Gado. All rights reserved.
//

import Foundation
import GoogleMaps

class Pin : NSObject {
    
    let name: String
    let location: CLLocationCoordinate2D
    let zoom: Float
    
    init(name: String, location: CLLocationCoordinate2D, zoom: Float) {
        self.name = name
        self.location = location
        self.zoom = zoom
    }
}
