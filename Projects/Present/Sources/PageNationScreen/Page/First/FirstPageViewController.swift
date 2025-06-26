//
//  FirstPageViewController.swift
//  Present
//
//  Created by Den on 4/29/25.
//  Copyright © 2025 Den. All rights reserved.
//

import UIKit

import Utility
import ThirdPartyLibrary
import DesignSystem

import SnapKit
import ReactorKit
import RxSwift

final class FirstPageViewController: BaseViewController {
    
    private let mainview = PageView()
    private var onboardingView: UIView?
    
    override func loadView() {
        super.view = mainview
    }
    
    init(reactor: FirstPageReactor) {
        super.init()
        self.reactor = reactor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

}

extension FirstPageViewController: View {
    func bind(reactor: FirstPageReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindAction(reactor: FirstPageReactor) {
        viewDidLoadEvent
            .map { Reactor.Action.viewDidLoadTrigger }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: FirstPageReactor) {
        reactor.state
            .map(\.themaNumber)
            .bind(with: self) { owner, num in
                print("[디버깅] themaNumber 변경: \(num)")
                owner.mainview.configureFirstPage()
            }
            .disposed(by: disposeBag)

    }
}
