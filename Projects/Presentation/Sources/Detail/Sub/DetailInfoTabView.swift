//
//  DetailInfoTabView.swift
//  Presentation
//
//  Created by 이윤수 on 7/13/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import DesignSystem
import Domain
import Resource

struct DetailInfoTabView: View {
    @Binding var intro: TouristSpotIntro
    @Binding var detail: TouristSpotDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            self.overviewSection()
            self.infoRowList()
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - View

private extension DetailInfoTabView {
    @ViewBuilder
    func overviewSection() -> some View {
        if let overview = self.detail.overview {
            TabiLabel(title: overview, style: .bodyM, color: .tabiTextSecondary, isExpanded: true)
                .lineSpacing(6)
        }
    }

    @ViewBuilder
    func infoRowList() -> some View {
        VStack(spacing: 10) {
            if let openTime = self.introFields.openTime {
                DetailInfoRow(
                    systemName: "clock",
                    label: Strings.Detail.infoOpenTime,
                    value: openTime,
                    color: self.detail.contentType.color
                )
            }
            if let restDate = self.introFields.restDate {
                DetailInfoRow(
                    systemName: "calendar.badge.minus",
                    label: Strings.Detail.infoRestDate,
                    value: restDate,
                    color: self.detail.contentType.color
                )
            }
            if let tel = self.detail.tel {
                DetailInfoRow(
                    systemName: "phone",
                    label: Strings.Detail.infoPhone,
                    value: tel,
                    color: self.detail.contentType.color
                )
            }
            if let parking = self.introFields.parking {
                DetailInfoRow(
                    systemName: "car",
                    label: Strings.Detail.infoParking,
                    value: parking,
                    color: self.detail.contentType.color
                )
            }
            DetailInfoRow(
                systemName: "mappin",
                label: Strings.Detail.infoAddress,
                value: self.detail.address,
                color: self.detail.contentType.color
            )
            if let homepage = self.detail.homepageURLString {
                DetailInfoRow(
                    systemName: "globe",
                    label: Strings.Detail.infoHomepage,
                    value: homepage,
                    color: self.detail.contentType.color
                )
            }
            if let experienceGuide = self.introFields.experienceGuide {
                DetailInfoRow(
                    systemName: "info.circle",
                    label: Strings.Detail.infoExperienceGuide,
                    value: experienceGuide,
                    color: self.detail.contentType.color
                )
            }
            if let experienceAgeRange = self.introFields.experienceAgeRange {
                DetailInfoRow(
                    systemName: "person.2",
                    label: Strings.Detail.infoExperienceAgeRange,
                    value: experienceAgeRange,
                    color: self.detail.contentType.color
                )
            }
            if let useSeason = self.introFields.useSeason {
                DetailInfoRow(
                    systemName: "leaf",
                    label: Strings.Detail.infoUseSeason,
                    value: useSeason,
                    color: self.detail.contentType.color
                )
            }
        }
    }

    var introFields: (
        openTime: String?,
        restDate: String?,
        parking: String?,
        experienceGuide: String?,
        experienceAgeRange: String?,
        useSeason: String?
    ) {
        switch self.intro {
        case .sightseeing(let intro):
            return (intro.openTime, intro.restDate, intro.parking, intro.experienceGuide, intro.experienceAgeRange, intro.useSeason)
        case .nature(let intro):
            return (intro.openTime, intro.restDate, intro.parking, nil, intro.experienceAgeRange, nil)
        case .food(let intro):
            return (intro.openTime, intro.restDate, intro.parking, nil, nil, nil)
        case .hotel(let intro):
            return (nil, nil, intro.parking, nil, nil, nil)
        case .festival:
            return (nil, nil, nil, nil, nil, nil)
        case .shopping(let intro):
            return (intro.openTime, intro.restDate, intro.parking, nil, nil, nil)
        }
    }
}
