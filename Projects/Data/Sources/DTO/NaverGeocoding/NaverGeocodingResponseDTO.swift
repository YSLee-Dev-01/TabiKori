//
//  NaverGeocodingResponseDTO.swift
//  Data
//
//  Created by 이윤수 on 8/6/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Core
import Domain

struct NaverGeocodingResponseDTO: Decodable {
    let status: String
    let meta: Meta?
    let addresses: [AddressDTO]?
    let errorMessage: String?

    struct Meta: Decodable {
        let totalCount: Int
    }

    struct AddressDTO: Decodable {
        let roadAddress: String
        let jibunAddress: String
        let x: String
        let y: String
    }
}

// MARK: - Mapping

extension NaverGeocodingResponseDTO {
    func toEntity() throws -> GeocodedAddress {
        guard self.status == "OK" else {
            AppLogger.network.log(.error, "❌ Geocoding 실패: \(self.status) \(self.errorMessage ?? "")")
            throw TabiError.dataNotFound
        }

        guard let firstAddress = self.addresses?.first,
              let longitude = firstAddress.x.toDouble(),
              let latitude = firstAddress.y.toDouble() else {
            AppLogger.network.log(.error, "❌ Geocoding 결과 없음 또는 좌표 파싱 실패: totalCount=\(self.meta?.totalCount ?? 0)")
            throw TabiError.dataNotFound
        }

        let formattedAddress = firstAddress.roadAddress.isEmpty ? firstAddress.jibunAddress : firstAddress.roadAddress

        return GeocodedAddress(
            coordinate: Coordinate(latitude: latitude, longitude: longitude),
            formattedAddress: formattedAddress
        )
    }
}
