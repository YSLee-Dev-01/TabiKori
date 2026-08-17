//
//  StackPath.swift
//  Presentation
//
//  Created by 이윤수 on 7/12/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import ComposableArchitecture

@Reducer
public enum StackPath {
    case detail(DetailFeature)
    case photoViewer(PhotoViewerFeature)
    case planDetail(PlanDetailFeature)
    case festival(FestivalFeature)
    case region(RegionSpotFeature)
    case setting(SettingFeature)
    case planToolBar(PlanToolBarFeature)
}

extension StackPath.State: Equatable {}
extension StackPath.Action: Equatable {}
