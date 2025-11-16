//
//  StatisticsReactor.swift
//  Present
//
//  Created by Den on 11/16/25.
//  Copyright © 2025 Den. All rights reserved.
//

import Foundation

import Utility
import ThirdPartyLibrary
import Domain

import ReactorKit
import RxSwift

final class StatisticsReactor: Reactor {
    
    @Injected private var userUseCase: UserUseCaseInterface

    var initialState = State()
    
    enum Action {
        case viewDidLoadTrigger
        case segmentControlDidChange(Int)
    }
    
    enum Mutation {
        case userData([UserEntity])
        case segmentValueChanged(Int)
    }
    
    struct State {
        var userData: [UserEntity] = []
        var segmentValue: Int = 0
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoadTrigger:
            let user = userUseCase.excuteFetchUser()
            return .concat([.just(.userData(user))])
        case .segmentControlDidChange(let value):
            return .concat([.just(.segmentValueChanged(value))])
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        
        switch mutation {
        case .userData(let userData):
            state.userData = userData
        case .segmentValueChanged(let value):
            state.segmentValue = value
        }
        return state
    }
}
