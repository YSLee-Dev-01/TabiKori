//
//  SettingInfoFeature.swift
//  Presentation
//
//  Created by 이윤수 on 8/11/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import Foundation

import ComposableArchitecture
import Core
import Domain

@Reducer
public struct SettingInfoFeature: Sendable {

    @Dependency(\.dismiss) var dismiss
    @Dependency(\.settingInfoUseCase) var settingInfoUseCase

    @ObservableState
    public struct State: Equatable {
        let contentType: SettingInfoContentType
        /// 화면에 표시할 본문. 하드코딩된 폴백 문구로 초기화되고, RTDB 로드에 성공하면 교체된다
        var displayedContent: String

        public init(contentType: SettingInfoContentType) {
            self.contentType = contentType
            self.displayedContent = contentType.content
        }
    }

    public enum Action: Equatable {
        case onAppear
        case closeTapped
        case contentLoaded(String)
    }

    public init() {}

    public var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return self.loadRemoteContentEffect(contentType: state.contentType)

            case .closeTapped:
                return .run { [dismiss = self.dismiss] _ in await dismiss() }

            case .contentLoaded(let content):
                state.displayedContent = content
                return .none
            }
        }
    }
}

// MARK: - Method

private extension SettingInfoFeature {
    /// 데이터 출처/기타 정보는 Firebase RTDB에서 로드한다. 라이선스는 정적 텍스트이므로 대상에서 제외한다.
    /// 로드 실패 시 별도 액션을 보내지 않아 State 초기값(하드코딩 폴백 문구)이 그대로 유지된다
    func loadRemoteContentEffect(contentType: SettingInfoContentType) -> Effect<Action> {
        switch contentType {
        case .dataSource:
            return .run { [settingInfoUseCase = self.settingInfoUseCase] send in
                do {
                    let content = try await settingInfoUseCase.fetchDataSourceContent()
                    await send(.contentLoaded(content))
                } catch {
                    AppLogger.network.log(.error, "데이터 출처 안내 로드 실패, 폴백 텍스트 유지: \(error.localizedDescription)")
                }
            }

        case .etcInfo:
            return .run { [settingInfoUseCase = self.settingInfoUseCase] send in
                do {
                    let content = try await settingInfoUseCase.fetchEtcInfoContent()
                    await send(.contentLoaded(content))
                } catch {
                    AppLogger.network.log(.error, "기타 정보 안내 로드 실패, 폴백 텍스트 유지: \(error.localizedDescription)")
                }
            }

        case .license:
            return .none
        }
    }
}
