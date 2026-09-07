//
//  SubwayStationResource.swift
//  Resource
//
//  Created by 이윤수 on 8/17/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public enum SubwayStationResource {
    public static func loadData() -> Data? {
        guard let url = Bundle.module.url(forResource: "seoul_subway_station", withExtension: "json") else {
            return nil
        }
        return try? Data(contentsOf: url)
    }

    public static func loadGeomData() -> Data? {
        guard let url = Bundle.module.url(forResource: "seoul_subway_station_geom", withExtension: "json") else {
            return nil
        }
        return try? Data(contentsOf: url)
    }
}
