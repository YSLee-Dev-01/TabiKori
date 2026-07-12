//
//  TouristSpotIntroDTO.swift
//  Data
//
//  Created by 이윤수 on 7/12/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import Core
import Domain

struct TouristSpotIntroResponseDTO: Decodable {
    let response: ResponseBody

    struct ResponseBody: Decodable {
        let header: Header
        let body: Body
    }

    struct Header: Decodable {
        let resultCode: String
        let resultMsg: String
    }

    struct Body: Decodable {
        let items: Items
    }

    struct Items: Decodable {
        let item: [TouristSpotIntroItemDTO]

        init(from decoder: Decoder) throws {
            if let singleValueContainer = try? decoder.singleValueContainer(),
               (try? singleValueContainer.decode(String.self)) != nil {
                self.item = []
                return
            }

            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.item = try container.decodeIfPresent([TouristSpotIntroItemDTO].self, forKey: .item) ?? []
        }

        enum CodingKeys: String, CodingKey {
            case item
        }
    }
}

struct TouristSpotIntroItemDTO: Decodable {
    let contentid: String
    let contenttypeid: String

    // Sightseeing (76)
    let accomcount: String?
    let expagerange: String?
    let expguide: String?
    let infocenter: String?
    let opendate: String?
    let parking: String?
    let restdate: String?
    let useseason: String?
    let usetime: String?

    // Nature/Leports (75)
    let accomcountleports: String?
    let expagerangeleports: String?
    let infocenterleports: String?
    let openperiod: String?
    let parkingfeeleports: String?
    let parkingleports: String?
    let reservation: String?
    let restdateleports: String?
    let scaleleports: String?
    let usefeeleports: String?
    let usetimeleports: String?

    // Food (82)
    let firstmenu: String?
    let infocenterfood: String?
    let opendatefood: String?
    let opentimefood: String?
    let parkingfood: String?
    let reservationfood: String?
    let restdatefood: String?
    let scalefood: String?
    let seat: String?
    let smoking: String?
    let treatmenu: String?
    let lcnsno: String?

    // Hotel (80)
    let accomcountlodging: String?
    let checkintime: String?
    let checkouttime: String?
    let chkcooking: String?
    let foodplace: String?
    let infocenterlodging: String?
    let parkinglodging: String?
    let pickup: String?
    let roomcount: String?
    let reservationlodging: String?
    let reservationurl: String?
    let roomtype: String?
    let scalelodging: String?
    let subfacility: String?

    // Festival (85)
    let agelimit: String?
    let bookingplace: String?
    let discountinfofestival: String?
    let eventenddate: String?
    let eventhomepage: String?
    let eventplace: String?
    let eventstartdate: String?
    let placeinfo: String?
    let playtime: String?
    let program: String?
    let spendtimefestival: String?
    let sponsor1: String?
    let sponsor1tel: String?
    let sponsor2: String?
    let sponsor2tel: String?
    let subevent: String?
    let usetimefestival: String?

    // Shopping (79)
    let fairday: String?
    let infocentershopping: String?
    let opendateshopping: String?
    let opentime: String?
    let parkingshopping: String?
    let restdateshopping: String?
    let restroom: String?
    let saleitem: String?
    let scaleshopping: String?
    let shopguide: String?
}

// MARK: - Mapping

extension TouristSpotIntroResponseDTO {
    func toEntity() throws -> TouristSpotIntro {
        guard self.response.header.resultCode == "0000" else {
            AppLogger.network.log(.error, "❌ 관광지 소개 조회 실패: \(self.response.header.resultCode) \(self.response.header.resultMsg)")
            throw TabiError.apiFailed(
                code: self.response.header.resultCode,
                message: self.response.header.resultMsg
            )
        }
        guard let item = self.response.body.items.item.first else {
            AppLogger.network.log(.error, "❌ 관광지 소개 데이터 없음")
            throw TabiError.apiFailed(code: "EMPTY", message: "No intro item found")
        }
        return try item.toEntity()
    }
}

private extension TouristSpotIntroItemDTO {
    func toEntity() throws -> TouristSpotIntro {
        guard let contentType = CategoryType(apiCode: self.contenttypeid) else {
            AppLogger.network.log(.error, "❌ 알 수 없는 contenttypeid: \(self.contenttypeid)")
            throw TabiError.apiFailed(code: "UNKNOWN_TYPE", message: "Unknown contenttypeid: \(self.contenttypeid)")
        }

        switch contentType {
        case .sightseeing:
            return .sightseeing(SightseeingIntro(
                contact: self.infocenter?.nilIfEmpty,
                openTime: self.usetime?.nilIfEmpty,
                restDate: self.restdate?.nilIfEmpty,
                parking: self.parking?.nilIfEmpty,
                openDate: self.opendate?.nilIfEmpty,
                experienceGuide: self.expguide?.nilIfEmpty,
                experienceAgeRange: self.expagerange?.nilIfEmpty,
                useSeason: self.useseason?.nilIfEmpty,
                accommodationCount: self.accomcount?.nilIfEmpty
            ))
        case .nature:
            return .nature(NatureIntro(
                contact: self.infocenterleports?.nilIfEmpty,
                openTime: self.usetimeleports?.nilIfEmpty,
                restDate: self.restdateleports?.nilIfEmpty,
                parking: self.parkingleports?.nilIfEmpty,
                parkingFee: self.parkingfeeleports?.nilIfEmpty,
                reservation: self.reservation?.nilIfEmpty,
                openPeriod: self.openperiod?.nilIfEmpty,
                useFee: self.usefeeleports?.nilIfEmpty,
                scale: self.scaleleports?.nilIfEmpty,
                experienceAgeRange: self.expagerangeleports?.nilIfEmpty,
                accommodationCount: self.accomcountleports?.nilIfEmpty
            ))
        case .food:
            return .food(FoodIntro(
                contact: self.infocenterfood?.nilIfEmpty,
                openTime: self.opentimefood?.nilIfEmpty,
                restDate: self.restdatefood?.nilIfEmpty,
                parking: self.parkingfood?.nilIfEmpty,
                mainMenu: self.firstmenu?.nilIfEmpty,
                menu: self.treatmenu?.nilIfEmpty,
                seatCount: self.seat?.nilIfEmpty,
                smokingInfo: self.smoking?.nilIfEmpty,
                reservation: self.reservationfood?.nilIfEmpty,
                openDate: self.opendatefood?.nilIfEmpty,
                scale: self.scalefood?.nilIfEmpty,
                licenseNumber: self.lcnsno?.nilIfEmpty
            ))
        case .hotel:
            return .hotel(HotelIntro(
                contact: self.infocenterlodging?.nilIfEmpty,
                parking: self.parkinglodging?.nilIfEmpty,
                checkInTime: self.checkintime?.nilIfEmpty,
                checkOutTime: self.checkouttime?.nilIfEmpty,
                roomCount: self.roomcount?.nilIfEmpty,
                roomType: self.roomtype?.nilIfEmpty,
                cookingAvailable: self.chkcooking?.nilIfEmpty,
                diningPlace: self.foodplace?.nilIfEmpty,
                pickupService: self.pickup?.nilIfEmpty,
                reservation: self.reservationlodging?.nilIfEmpty,
                reservationURL: self.reservationurl?.nilIfEmpty,
                subFacility: self.subfacility?.nilIfEmpty,
                scale: self.scalelodging?.nilIfEmpty,
                accommodationCount: self.accomcountlodging?.nilIfEmpty
            ))
        case .festival:
            return .festival(FestivalIntro(
                eventPlace: self.eventplace?.nilIfEmpty,
                startDate: self.eventstartdate?.nilIfEmpty,
                endDate: self.eventenddate?.nilIfEmpty,
                playTime: self.playtime?.nilIfEmpty,
                program: self.program?.nilIfEmpty,
                useFee: self.usetimefestival?.nilIfEmpty,
                ageLimit: self.agelimit?.nilIfEmpty,
                bookingPlace: self.bookingplace?.nilIfEmpty,
                homePage: self.eventhomepage?.nilIfEmpty,
                discountInfo: self.discountinfofestival?.nilIfEmpty,
                sponsor: self.sponsor1?.nilIfEmpty,
                sponsorTel: self.sponsor1tel?.nilIfEmpty,
                coSponsor: self.sponsor2?.nilIfEmpty,
                coSponsorTel: self.sponsor2tel?.nilIfEmpty,
                placeInfo: self.placeinfo?.nilIfEmpty,
                spendTime: self.spendtimefestival?.nilIfEmpty,
                subEvent: self.subevent?.nilIfEmpty
            ))
        case .shopping:
            return .shopping(ShoppingIntro(
                contact: self.infocentershopping?.nilIfEmpty,
                openTime: self.opentime?.nilIfEmpty,
                restDate: self.restdateshopping?.nilIfEmpty,
                parking: self.parkingshopping?.nilIfEmpty,
                saleItems: self.saleitem?.nilIfEmpty,
                openDate: self.opendateshopping?.nilIfEmpty,
                fairDay: self.fairday?.nilIfEmpty,
                restroom: self.restroom?.nilIfEmpty,
                scale: self.scaleshopping?.nilIfEmpty,
                shopGuide: self.shopguide?.nilIfEmpty
            ))
        }
    }
}

// MARK: - String Helper

private extension String {
    var nilIfEmpty: String? {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
