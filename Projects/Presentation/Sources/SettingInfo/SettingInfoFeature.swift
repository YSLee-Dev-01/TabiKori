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
        /// 화면에 표시할 본문의 로딩 상태. 라이선스는 정적 텍스트이므로 로딩 없이 즉시 표시된다
        var loadState: LoadState

        public init(contentType: SettingInfoContentType) {
            self.contentType = contentType
            switch contentType {
            case .license:
                self.loadState = .loaded(contentType.content)

            case .dataSource, .etcInfo:
                self.loadState = .loading
            }
        }
    }

    public enum LoadState: Equatable {
        case loading
        case loaded(String)
        case fallback(String)
    }

    public enum Action: Equatable {
        case onAppear
        case closeTapped
        case contentLoaded(String)
        case contentLoadFailed
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
                state.loadState = .loaded(content)
                return .none

            case .contentLoadFailed:
                state.loadState = .fallback(state.contentType.content)
                return .none
            }
        }
    }
}

// MARK: - Method

private extension SettingInfoFeature {
    /// 데이터 출처/기타 정보는 Firebase RTDB에서 로드한다. 라이선스는 정적 텍스트이므로 대상에서 제외한다.
    /// 로드 실패 시 `contentLoadFailed`를 보내 폴백 문구로 전환한다
    func loadRemoteContentEffect(contentType: SettingInfoContentType) -> Effect<Action> {
        switch contentType {
        case .dataSource:
            return .run { [settingInfoUseCase = self.settingInfoUseCase] send in
                do {
                    let content = try await settingInfoUseCase.fetchDataSourceContent()
                    await send(.contentLoaded(content))
                } catch {
                    AppLogger.network.log(.error, "데이터 출처 안내 로드 실패, 폴백 텍스트로 전환: \(error.localizedDescription)")
                    await send(.contentLoadFailed)
                }
            }

        case .etcInfo:
            return .run { [settingInfoUseCase = self.settingInfoUseCase] send in
                do {
                    let content = try await settingInfoUseCase.fetchEtcInfoContent()
                    await send(.contentLoaded(content))
                } catch {
                    AppLogger.network.log(.error, "기타 정보 안내 로드 실패, 폴백 텍스트로 전환: \(error.localizedDescription)")
                    await send(.contentLoadFailed)
                }
            }

        case .license:
            return .none
        }
    }
}
