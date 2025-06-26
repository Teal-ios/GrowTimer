//
//  PageNationViewController.swift
//  Present
//
//  Created by Den on 4/29/25.
//  Copyright © 2025 Den. All rights reserved.
//

import UIKit

import ThirdPartyLibrary
import DesignSystem
import Utility

import RxSwift
import RxCocoa
import ReactorKit

final class PageNationViewController: UIPageViewController {
    
    var disposeBag = DisposeBag()
    
    private var onboardingView: UIView?
    
    lazy var navigationView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemaManager.shared.mainColor
        return view
    }()

    //뷰컨트롤러 배열

    lazy var vc1: UIViewController = {
        let vc = FirstPageViewController(reactor: FirstPageReactor())
        return vc
    }()

    lazy var vc2: UIViewController = {
        let vc = SecondPageViewController()
        return vc
    }()

    lazy var vc3: UIViewController = {
        let vc = FinalPageViewController(reactor: FinalPageReactor())
        return vc
    }()
    
    lazy var dataViewControllers: [UIViewController] = {
        return [vc1, vc2, vc3]
    }()
    
    lazy var pageViewController: UIPageViewController = {
        let vc = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)

        return vc
    }()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // viewDidLoad()에서 호출
        if let firstVC = dataViewControllers.first {
            pageViewController.setViewControllers([firstVC], direction: .forward, animated: true, completion: nil)
        }
        
        configure()
        setupDelegate()
        
        // 온보딩 가이드 최초 1회 노출
        if !UserDefaultManager.hasSeenFirstPageOnboarding {
            showOnboardingGuide()
        }
    }
    
    
    private func configure() {
        view.addSubview(navigationView)
        addChild(pageViewController)
        view.addSubview(pageViewController.view)

        navigationView.snp.makeConstraints { make in
            make.width.top.equalToSuperview()
            make.height.equalTo(72)
        }

        pageViewController.view.snp.makeConstraints { make in
            make.top.equalTo(navigationView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        pageViewController.didMove(toParent: self)

        func setupDelegate() {
            pageViewController.dataSource = self
            pageViewController.delegate = self
        }
    }
    
    private func setupDelegate() {
        pageViewController.dataSource = self
        pageViewController.delegate = self
    }

    private func showOnboardingGuide() {
        print("[디버깅] PageNationViewController showOnboardingGuide 호출")
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

        // 아무 곳이나 터치해도 가이드 종료
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapOnboarding))
        guideView.addGestureRecognizer(tapGesture)

        view.addSubview(guideView)
        onboardingView = guideView
    }

    private func hideOnboardingGuide() {
        print("[디버깅] PageNationViewController hideOnboardingGuide 호출")
        UIView.animate(withDuration: 0.3, animations: {
            self.onboardingView?.alpha = 0
        }) { _ in
            self.onboardingView?.removeFromSuperview()
            self.onboardingView = nil
        }
    }

    @objc private func didSwipeOnboarding() {
        print("[디버깅] PageNationViewController didSwipeOnboarding 호출")
        UserDefaultManager.hasSeenFirstPageOnboarding = true
        hideOnboardingGuide()
    }

    @objc private func didTapOnboarding() {
        print("[디버깅] PageNationViewController didTapOnboarding 호출")
        UserDefaultManager.hasSeenFirstPageOnboarding = true
        hideOnboardingGuide()
    }
}

extension PageNationViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = dataViewControllers.firstIndex(of: viewController) else { return nil }
        let previousIndex = index - 1
        if previousIndex < 0 {
            return nil
        }
        return dataViewControllers[previousIndex]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = dataViewControllers.firstIndex(of: viewController) else { return nil }
        let nextIndex = index + 1
        if nextIndex == dataViewControllers.count {
            return nil
        }
        return dataViewControllers[nextIndex]
    }
}

extension PageNationViewController: View {
    func bind(reactor: PageNationReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
    
    private func bindAction(reactor: PageNationReactor) {
        viewDidLoadEvent
            .map { Reactor.Action.viewDidLoadTrigger }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: PageNationReactor) {
        reactor.state
            .map(\.themaNumber)
            .bind(with: self) { owner, num in
                owner.navigationView.backgroundColor = ThemaManager.shared.mainColor
            }
            .disposed(by: disposeBag)
    }
}
