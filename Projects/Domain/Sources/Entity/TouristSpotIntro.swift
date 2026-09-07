//
//  TouristSpotIntro.swift
//  Domain
//
//  Created by 이윤수 on 7/12/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public enum TouristSpotIntro: Equatable, Sendable {
    case sightseeing(SightseeingIntro)
    case nature(NatureIntro)
    case food(FoodIntro)
    case hotel(HotelIntro)
    case festival(FestivalIntro)
    case shopping(ShoppingIntro)
}

// MARK: - Sightseeing (76)

public struct SightseeingIntro: Equatable, Sendable {
    public let contact: String?
    public let openTime: String?
    public let restDate: String?
    public let parking: String?
    public let openDate: String?
    public let experienceGuide: String?
    public let experienceAgeRange: String?
    public let useSeason: String?
    public let accommodationCount: String?

    public init(
        contact: String?,
        openTime: String?,
        restDate: String?,
        parking: String?,
        openDate: String?,
        experienceGuide: String?,
        experienceAgeRange: String?,
        useSeason: String?,
        accommodationCount: String?
    ) {
        self.contact = contact
        self.openTime = openTime
        self.restDate = restDate
        self.parking = parking
        self.openDate = openDate
        self.experienceGuide = experienceGuide
        self.experienceAgeRange = experienceAgeRange
        self.useSeason = useSeason
        self.accommodationCount = accommodationCount
    }
}

// MARK: - Nature/Leports (75)

public struct NatureIntro: Equatable, Sendable {
    public let contact: String?
    public let openTime: String?
    public let restDate: String?
    public let parking: String?
    public let parkingFee: String?
    public let reservation: String?
    public let openPeriod: String?
    public let useFee: String?
    public let scale: String?
    public let experienceAgeRange: String?
    public let accommodationCount: String?

    public init(
        contact: String?,
        openTime: String?,
        restDate: String?,
        parking: String?,
        parkingFee: String?,
        reservation: String?,
        openPeriod: String?,
        useFee: String?,
        scale: String?,
        experienceAgeRange: String?,
        accommodationCount: String?
    ) {
        self.contact = contact
        self.openTime = openTime
        self.restDate = restDate
        self.parking = parking
        self.parkingFee = parkingFee
        self.reservation = reservation
        self.openPeriod = openPeriod
        self.useFee = useFee
        self.scale = scale
        self.experienceAgeRange = experienceAgeRange
        self.accommodationCount = accommodationCount
    }
}

// MARK: - Food (82)

public struct FoodIntro: Equatable, Sendable {
    public let contact: String?
    public let openTime: String?
    public let restDate: String?
    public let parking: String?
    public let mainMenu: String?
    public let menu: String?
    public let seatCount: String?
    public let smokingInfo: String?
    public let reservation: String?
    public let openDate: String?
    public let scale: String?
    public let licenseNumber: String?

    public init(
        contact: String?,
        openTime: String?,
        restDate: String?,
        parking: String?,
        mainMenu: String?,
        menu: String?,
        seatCount: String?,
        smokingInfo: String?,
        reservation: String?,
        openDate: String?,
        scale: String?,
        licenseNumber: String?
    ) {
        self.contact = contact
        self.openTime = openTime
        self.restDate = restDate
        self.parking = parking
        self.mainMenu = mainMenu
        self.menu = menu
        self.seatCount = seatCount
        self.smokingInfo = smokingInfo
        self.reservation = reservation
        self.openDate = openDate
        self.scale = scale
        self.licenseNumber = licenseNumber
    }
}

// MARK: - Hotel (80)

public struct HotelIntro: Equatable, Sendable {
    public let contact: String?
    public let parking: String?
    public let checkInTime: String?
    public let checkOutTime: String?
    public let roomCount: String?
    public let roomType: String?
    public let cookingAvailable: String?
    public let diningPlace: String?
    public let pickupService: String?
    public let reservation: String?
    public let reservationURL: String?
    public let subFacility: String?
    public let scale: String?
    public let accommodationCount: String?

    public init(
        contact: String?,
        parking: String?,
        checkInTime: String?,
        checkOutTime: String?,
        roomCount: String?,
        roomType: String?,
        cookingAvailable: String?,
        diningPlace: String?,
        pickupService: String?,
        reservation: String?,
        reservationURL: String?,
        subFacility: String?,
        scale: String?,
        accommodationCount: String?
    ) {
        self.contact = contact
        self.parking = parking
        self.checkInTime = checkInTime
        self.checkOutTime = checkOutTime
        self.roomCount = roomCount
        self.roomType = roomType
        self.cookingAvailable = cookingAvailable
        self.diningPlace = diningPlace
        self.pickupService = pickupService
        self.reservation = reservation
        self.reservationURL = reservationURL
        self.subFacility = subFacility
        self.scale = scale
        self.accommodationCount = accommodationCount
    }
}

// MARK: - Festival (85)

public struct FestivalIntro: Equatable, Sendable {
    public let eventPlace: String?
    public let startDate: String?
    public let endDate: String?
    public let playTime: String?
    public let program: String?
    public let useFee: String?
    public let ageLimit: String?
    public let bookingPlace: String?
    public let homePage: String?
    public let discountInfo: String?
    public let sponsor: String?
    public let sponsorTel: String?
    public let coSponsor: String?
    public let coSponsorTel: String?
    public let placeInfo: String?
    public let spendTime: String?
    public let subEvent: String?

    public init(
        eventPlace: String?,
        startDate: String?,
        endDate: String?,
        playTime: String?,
        program: String?,
        useFee: String?,
        ageLimit: String?,
        bookingPlace: String?,
        homePage: String?,
        discountInfo: String?,
        sponsor: String?,
        sponsorTel: String?,
        coSponsor: String?,
        coSponsorTel: String?,
        placeInfo: String?,
        spendTime: String?,
        subEvent: String?
    ) {
        self.eventPlace = eventPlace
        self.startDate = startDate
        self.endDate = endDate
        self.playTime = playTime
        self.program = program
        self.useFee = useFee
        self.ageLimit = ageLimit
        self.bookingPlace = bookingPlace
        self.homePage = homePage
        self.discountInfo = discountInfo
        self.sponsor = sponsor
        self.sponsorTel = sponsorTel
        self.coSponsor = coSponsor
        self.coSponsorTel = coSponsorTel
        self.placeInfo = placeInfo
        self.spendTime = spendTime
        self.subEvent = subEvent
    }
}

// MARK: - Shopping (79)

public struct ShoppingIntro: Equatable, Sendable {
    public let contact: String?
    public let openTime: String?
    public let restDate: String?
    public let parking: String?
    public let saleItems: String?
    public let openDate: String?
    public let fairDay: String?
    public let restroom: String?
    public let scale: String?
    public let shopGuide: String?

    public init(
        contact: String?,
        openTime: String?,
        restDate: String?,
        parking: String?,
        saleItems: String?,
        openDate: String?,
        fairDay: String?,
        restroom: String?,
        scale: String?,
        shopGuide: String?
    ) {
        self.contact = contact
        self.openTime = openTime
        self.restDate = restDate
        self.parking = parking
        self.saleItems = saleItems
        self.openDate = openDate
        self.fairDay = fairDay
        self.restroom = restroom
        self.scale = scale
        self.shopGuide = shopGuide
    }
}
