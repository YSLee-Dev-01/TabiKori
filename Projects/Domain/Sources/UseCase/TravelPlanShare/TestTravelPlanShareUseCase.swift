//
//  TestTravelPlanShareUseCase.swift
//  Domain
//
//  Created by 이윤수 on 8/14/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

public final class TestTravelPlanShareUseCase: TravelPlanShareUseCaseProtocol, @unchecked Sendable {

    // MARK: - Properties

    public var exportDataResult: Data = Data()
    public var importPlanResult: (plan: TravelPlan, detail: TravelPlanDetail)?
    public var shouldThrowOnExport: Bool = false
    public var shouldThrowOnImport: Bool = false

    // MARK: - Init

    public init() {}

    // MARK: - Method

    public func exportData(plan: TravelPlan, detail: TravelPlanDetail?) throws -> Data {
        if self.shouldThrowOnExport {
            throw TabiError.decodingFailed(message: "테스트 내보내기 실패")
        }
        return self.exportDataResult
    }

    public func importPlan(from data: Data) throws -> (plan: TravelPlan, detail: TravelPlanDetail) {
        if self.shouldThrowOnImport {
            throw TabiError.decodingFailed(message: "테스트 가져오기 실패")
        }
        guard let importPlanResult else {
            throw TabiError.decodingFailed(message: "테스트 가져오기 결과가 설정되지 않음")
        }
        return importPlanResult
    }
}
