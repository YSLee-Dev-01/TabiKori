//
//  SettingView.swift
//  Presentation
//
//  Created by 이윤수 on 8/11/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

import ComposableArchitecture
import DesignSystem
import Resource

public struct SettingView: View {

    @Bindable private var store: StoreOf<SettingFeature>
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    public init(store: StoreOf<SettingFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                self.gpsSection()
                self.dataResetSection()
                self.etcSection()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle(Strings.Setting.screenTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    self.dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
                .tint(Color.getTabiColor(.tabiPrimary))
                .disabled(self.store.isResetting)
            }
        }
        .navigationBarBackButtonHidden(true)
        .interactivePopGestureEnabled(self.store.isResetting == false)
        .sheet(item: self.$store.scope(state: \.infoState, action: \.info)) { store in
            SettingInfoView(store: store)
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .onAppear {
            self.store.send(.onAppear)
        }
        .onChange(of: self.scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            self.store.send(.scenePhaseBecameActive)
        }
    }
}

// MARK: - View

private extension SettingView {
    func gpsSection() -> some View {
        SettingSectionCard(title: Strings.Setting.gpsSectionTitle) {
            SettingRow(
                title: Strings.Setting.gpsRowTitle,
                value: self.gpsStatusText
            ) {
                self.store.send(.gpsRowTapped)
            }
        }
    }

    func dataResetSection() -> some View {
        SettingSectionCard(title: Strings.Setting.dataResetSectionTitle) {
            SettingRow(
                title: Strings.Setting.dataResetRowTitle,
                description: Strings.Setting.dataResetRowDescription,
                isDisabled: self.store.isResetting
            ) {
                self.store.send(.resetRowTapped)
            }
        }
    }

    func etcSection() -> some View {
        SettingSectionCard(title: Strings.Setting.etcSectionTitle) {
            ForEach(SettingEtcItem.allCases) { item in
                if item != SettingEtcItem.allCases.first {
                    Divider()
                        .padding(.leading, 16)
                }
                self.etcRow(item)
            }
        }
    }

    @ViewBuilder
    func etcRow(_ item: SettingEtcItem) -> some View {
        switch item.kind {
        case .staticText:
            SettingRow(title: item.title) {
                self.store.send(.etcRowTapped(item))
            }

        case .versionDisplay:
            SettingRow(title: item.title, value: SettingEtcItem.appVersionText)

        case .disabled:
            SettingRow(title: item.title, value: Strings.Setting.etcComingSoonLabel, isDisabled: true)
        }
    }

    var gpsStatusText: String {
        switch self.store.locationStatus {
        case .allowed: return Strings.Setting.gpsStatusAllowed
        case .denied: return Strings.Setting.gpsStatusDenied
        case .undetermined: return Strings.Setting.gpsStatusUndetermined
        }
    }
}
