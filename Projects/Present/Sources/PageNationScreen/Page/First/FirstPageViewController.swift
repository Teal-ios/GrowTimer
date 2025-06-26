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
    
    private func showOnboardingGuide() {
        print("[디버깅] showOnboardingGuide 호출")
        guard onboardingView == nil else { return }
        let guideView = UIView(frame: view.bounds)
        guideView.backgroundColor = UIColor.black.withAlphaComponent(0.7)

        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = guideView.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurView.alpha = 0.3
        guideView.addSubview(blurView)
        guideView.sendSubviewToBack(blurView)

        let label = UILabel()
        label.text = "오른쪽으로 슬라이드 하세요"
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 22)
        label.translatesAutoresizingMaskIntoConstraints = false
        guideView.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: guideView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: guideView.centerYAnchor, constant: -40)
        ])

        let fingerImageView = UIImageView()
        if let fingerImage = UIImage(systemName: "hand.point.right.fill") {
            fingerImageView.image = fingerImage
            fingerImageView.tintColor = .white
        }
        fingerImageView.translatesAutoresizingMaskIntoConstraints = false
        guideView.addSubview(fingerImageView)
        NSLayoutConstraint.activate([
            fingerImageView.widthAnchor.constraint(equalToConstant: 48),
            fingerImageView.heightAnchor.constraint(equalToConstant: 48),
            fingerImageView.centerXAnchor.constraint(equalTo: guideView.centerXAnchor),
            fingerImageView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 24)
        ])

        let moveDistance: CGFloat = 80
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            UIView.animateKeyframes(withDuration: 1.2, delay: 0, options: [.repeat, .autoreverse], animations: {
                fingerImageView.transform = CGAffineTransform(translationX: moveDistance, y: 0)
            }, completion: nil)
        }

        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeOnboarding))
        swipeGesture.direction = .right
        guideView.addGestureRecognizer(swipeGesture)

        view.addSubview(guideView)
        onboardingView = guideView
    }

    private func hideOnboardingGuide() {
        print("[디버깅] hideOnboardingGuide 호출")
        UIView.animate(withDuration: 0.3, animations: {
            self.onboardingView?.alpha = 0
        }) { _ in
            self.onboardingView?.removeFromSuperview()
            self.onboardingView = nil
        }
    }

    @objc private func didSwipeOnboarding() {
        print("[디버깅] didSwipeOnboarding 호출")
        if let reactor = self.reactor as? FirstPageReactor {
            reactor.action.onNext(.onboardingDidDismiss)
        }
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

        reactor.state
            .map(\.showOnboarding)
            .distinctUntilChanged()
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, show in
                print("[디버깅] showOnboarding 상태: \(show)")
                if show {
                    owner.showOnboardingGuide()
                } else {
                    owner.hideOnboardingGuide()
                }
            }
            .disposed(by: disposeBag)
    }
}
