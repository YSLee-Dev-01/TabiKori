//
//  View+.swift
//  Presentation
//
//  Created by 이윤수 on 8/2/26.
//  Copyright © 2026 yslee. All rights reserved.
//

import SwiftUI

public extension View {
    /// `NavigationStack`의 인터랙티브 스와이프 팝 제스처 활성화 여부를 강제로 지정한다.
    /// `.navigationBarBackButtonHidden(true)`가 인터랙티브 팝 제스처까지 함께 비활성화시키는 부작용을 우회하기 위해 사용한다
    func interactivePopGestureEnabled(_ isEnabled: Bool) -> some View {
        self.background(InteractivePopGestureConfigurator(isEnabled: isEnabled))
    }
}

// MARK: - InteractivePopGestureConfigurator

private struct InteractivePopGestureConfigurator: UIViewControllerRepresentable {
    let isEnabled: Bool

    func makeUIViewController(context: Context) -> InteractivePopGestureHostingController {
        InteractivePopGestureHostingController(isEnabled: self.isEnabled)
    }

    func updateUIViewController(_ uiViewController: InteractivePopGestureHostingController, context: Context) {
        uiViewController.isEnabled = self.isEnabled
    }
}

// MARK: - InteractivePopGestureHostingController

private final class InteractivePopGestureHostingController: UIViewController {
    var isEnabled: Bool {
        didSet { self.scheduleApplyGestureState() }
    }

    init(isEnabled: Bool) {
        self.isEnabled = isEnabled
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.scheduleApplyGestureState()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.scheduleApplyGestureState()
    }
}

// MARK: - Method

private extension InteractivePopGestureHostingController {
    /// `NavigationStack`이 같은 런루프 사이클에서 `interactivePopGestureRecognizer.isEnabled`를
    /// 다시 덮어쓰는 경우가 있어, 다음 런루프로 미뤄 마지막에 우리가 지정한 값이 적용되도록 한다
    func scheduleApplyGestureState() {
        DispatchQueue.main.async { [weak self] in
            self?.applyGestureState()
        }
    }

    func applyGestureState() {
        guard let recognizer = self.navigationController?.interactivePopGestureRecognizer else { return }
        recognizer.isEnabled = self.isEnabled
        if self.isEnabled {
            // `navigationBarBackButtonHidden(true)`가 내부적으로 delegate를 통해 제스처 시작을 막는 경우가 있어,
            // 활성화 시에는 delegate를 제거해 UINavigationController의 기본 동작(스택에 pop할 화면이 있으면 항상 허용)을 따르게 한다
            recognizer.delegate = nil
        }
    }
}
