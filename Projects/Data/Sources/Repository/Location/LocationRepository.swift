//
//  LocationRepository.swift
//  Data
//
//  Created by 이윤수 on 6/23/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Domain
import CoreLocation

public final class LocationRepository: NSObject, LocationRepositoryProtocol, @unchecked Sendable {
    
    private let locationManager: CLLocationManager
    private var authContinuation: CheckedContinuation<LocationAuthorizationStatus, Never>?
    
    public init(locationManager: CLLocationManager = .init()) {
        self.locationManager = locationManager
    }
    
    public func checkAuthorization() -> LocationAuthorizationStatus {
        return Self.mapAuthorizationStatus(self.locationManager.authorizationStatus)
    }
    
    public func requestAuthorization() async -> LocationAuthorizationStatus {
        return await withCheckedContinuation { continuation in
            self.authContinuation = continuation
            self.locationManager.requestWhenInUseAuthorization()
        }
    }
    
    fileprivate static func mapAuthorizationStatus(_ status: CLAuthorizationStatus) -> LocationAuthorizationStatus {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return .allowed
            
        case .restricted, .denied:
            return .denied
            
        default:
            return .undetermined
        }
    }
}

extension LocationRepository: CLLocationManagerDelegate {
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authContinuation?.resume(returning: Self.mapAuthorizationStatus(manager.authorizationStatus))
        self.authContinuation = nil
    }
}
