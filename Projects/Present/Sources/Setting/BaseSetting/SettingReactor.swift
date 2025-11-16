//
//  SettingReactor.swift
//  Present
//
//  Created by Den on 5/3/25.
//  Copyright © 2025 Den. All rights reserved.
//

import Foundation

import Utility
import ThirdPartyLibrary

import ReactorKit
import RxSwift

final class SettingReactor: Reactor {
    
    var initialState = State()
    
    enum Action {
        case cellTapped(IndexPath)
    }
    
    enum Mutation {
        case navigateToTime
        case navigateToThema
        case navigateToFont
        case navigateToStatistics
    }
    
    struct State {
        @Pulse var shouldNavigateToTime: Void?
        @Pulse var shouldNavigateToThema: Void?
        @Pulse var shouldNavigateToFont: Void?
        @Pulse var shouldNavigateToStatistics: Void?

        var settingList = ["집중 시간 설정", "집중시간 통계", "테마 변경/구매", "폰트 변경/구매"]
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
            
        case .cellTapped(let indexPath):
            switch indexPath.row {
            case 0:
                return .just(.navigateToTime)
            case 1:
                return .just(.navigateToStatistics)
            case 2:
                return .just(.navigateToThema)
            case 3:
                return .just(.navigateToFont)
            default:
                return .empty()
            }
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        
        switch mutation {
        case .navigateToTime:
            state.shouldNavigateToTime = ()
            return state
        case .navigateToFont:
            state.shouldNavigateToFont = ()
            return state
        case .navigateToThema:
            state.shouldNavigateToThema = ()
            return state
        case .navigateToStatistics:
            state.shouldNavigateToStatistics = ()
            return state
        }
    }
}
