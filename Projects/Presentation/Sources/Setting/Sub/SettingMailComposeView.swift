//
//  SettingMailComposeView.swift
//  Presentation
//
//  Created by Claude on 8/26/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import MessageUI
import SwiftUI

/// `MFMailComposeViewController`를 SwiftUI `.sheet`로 표시하기 위한 wrapper.
/// 문의하기(SettingView) 전용이며 재사용 가능성이 낮아 DesignSystem이 아닌 Setting 화면 내부에 위치한다
struct SettingMailComposeView: UIViewControllerRepresentable {

    let recipient: String
    let subject: String
    let onFinish: () -> Void

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients([self.recipient])
        controller.setSubject(self.subject)
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onFinish: self.onFinish)
    }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {

        private let onFinish: () -> Void

        init(onFinish: @escaping () -> Void) {
            self.onFinish = onFinish
        }

        func mailComposeController(
            _ controller: MFMailComposeViewController,
            didFinishWith result: MFMailComposeResult,
            error: Error?
        ) {
            controller.dismiss(animated: true)
            self.onFinish()
        }
    }
}
