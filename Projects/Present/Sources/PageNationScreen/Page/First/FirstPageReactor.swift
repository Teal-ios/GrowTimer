//
//  FirstPageReactor.swift
//  Present
//
//  Created by Den on 4/29/25.
//  Copyright © 2025 Den. All rights reserved.
//

import Foundation

import Utility
import ThirdPartyLibrary

import ReactorKit
import RxSwift

final class FirstPageReactor: Reactor {
    
    var initialState = State()
    
    enum Action {
        case viewDidLoadTrigger
        case onboardingDidDismiss // 온보딩 닫힘 액션
    }
    
    enum Mutation {
        case themaVale(Int)
        case viewDidLoadTrigger(Void)
        case setShowOnboarding(Bool) // 온보딩 노출 여부
    }
    
    struct State {
        var themaNumber: Int = 0
        var viewDidLoadTrigger: Void = ()
        var showOnboarding: Bool = false // 온보딩 노출 여부
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoadTrigger:
            let shouldShow = !UserDefaultManager.hasSeenFirstPageOnboarding
            return Observable.concat([
                Observable.just(.viewDidLoadTrigger(())),
                Observable.just(.themaVale(UserDefaultManager.thema)),
                Observable.just(.setShowOnboarding(shouldShow))
            ])
        case .onboardingDidDismiss:
            UserDefaultManager.hasSeenFirstPageOnboarding = true
            return Observable.just(.setShowOnboarding(false))
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
        case .themaVale(let themaNumber):
            state.themaNumber = themaNumber
        case .viewDidLoadTrigger(let event):
            state.viewDidLoadTrigger = event
        case .setShowOnboarding(let show):
            state.showOnboarding = show
        }
        return state
    }
}
