//
//  LocationRepository.swift
//  Data
//
//  Created by 이윤수 on 6/23/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Core
import Domain
import CoreLocation

public final class LocationRepository: NSObject, LocationRepositoryProtocol, @unchecked Sendable {

    private let locationManager: CLLocationManager
    private var authContinuation: CheckedContinuation<LocationAuthorizationStatus, Never>?
    private var coordinateContinuation: CheckedContinuation<Coordinate, Error>?
    private var authorizationTask: Task<LocationAuthorizationStatus, Never>?

    public init(locationManager: CLLocationManager = .init()) {
        self.locationManager = locationManager
        super.init()
        self.locationManager.delegate = self
    }

    public func checkAuthorization() -> LocationAuthorizationStatus {
        return Self.mapAuthorizationStatus(self.locationManager.authorizationStatus)
    }

    public func requestAuthorization() async -> LocationAuthorizationStatus {
        if let authorizationTask {
            return await authorizationTask.value
        }

        let task = Task<LocationAuthorizationStatus, Never> {
            await withCheckedContinuation { continuation in
                self.authContinuation = continuation
                self.locationManager.requestWhenInUseAuthorization()
            }
        }
        self.authorizationTask = task
        defer { self.authorizationTask = nil }
        return await task.value
    }

    public func fetchCurrentCoordinate() async throws -> Coordinate {
        #if targetEnvironment(simulator)
        return Coordinate(latitude: 37.5666102, longitude: 126.9783881)
        #else
        guard self.coordinateContinuation == nil else {
            throw TabiError.persistenceFailed(message: "이미 위치 요청이 진행 중입니다")
        }
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                self.coordinateContinuation = continuation
                self.locationManager.startUpdatingLocation()
            }
        } onCancel: { [weak self] in
            self?.locationManager.stopUpdatingLocation()
        }
        #endif
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

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        self.coordinateContinuation?.resume(returning: Coordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        ))
        self.coordinateContinuation = nil
        self.locationManager.stopUpdatingLocation()
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        AppLogger.core.log(.error, "위치 조회 실패: \(error.localizedDescription)")
        self.coordinateContinuation?.resume(throwing: error)
        self.coordinateContinuation = nil
        self.locationManager.stopUpdatingLocation()
    }
}
