//
//  HomeReactor.swift
//  Present
//
//  Created by Den on 4/30/25.
//  Copyright © 2025 Den. All rights reserved.
//

import Foundation

import Utility
import ThirdPartyLibrary
import Domain
import DesignSystem

import ReactorKit
import RxSwift

final class HomeReactor: Reactor {
    
    @Injected private var coinUseCase: CoinUseCaseInterface
    @Injected private var userUseCase: UserUseCaseInterface
    @Injected private var fontUseCase: FontUseCaseInterface
    @Injected private var themaUseCase: ThemaUseCaseInterface
    
    var initialState = State()
    private var timer: Disposable? // Rx의 Disposable로 타이머 정의
    
    enum Action {
        case viewDidLoadTrigger(CGFloat)
        case timerButtonTapped
        case timerTick
        case timerCompleted
        // Navigation 관련 Event
        case calendarButtonTapped
        case settingButtonTapped
        case bulbButtonTapped
        case timeLineButtonTapped
    }
    
    enum Mutation {
        case setTimerButtonState(Bool)
        case updateRemainingTime(Int)
        case updateProgress(Float)
        case setButtonTitle(String)
        case resetTimer
        case finishTimer
        case showToast(String)
        case clearToastMessage
        case stopChance(Int)
        
        case navigateToCalendar(Bool)
        case navigateToSetting(Bool)
        case toggleBulb
        case navigateToTimeLine(Bool)
        case navigateToFinishPopup(Bool)

        case getTotalCoin(Int)
        
        case userData([UserEntity])
    }
    
    struct State {
        var remainingTime: Int = UserDefaultManager.engagedTime
        var progress: Float = 0.0
        var isTimerRunning: Bool = false
        var buttonTitle: String = "시작"
        var stopChances: Int = UserDefaultManager.stopCount
        var firstStartButtonClicked: Bool = true
        var toastMessage: String?
        // 전체 시간을 초기화에 저장하여 progress 계산에 사용
        var totalTime: Int = UserDefaultManager.engagedTime
        
        // 필요하다면 네비게이션 관련 상태 추가
        var shouldNavigateToCalendar: Bool = false
        var shouldNavigateToSetting: Bool = false
        var shouldToggleBulb: Bool = false
        var shouldNavigateToTimeLine: Bool = false
        var shouldNavigateToFinishPopup: Bool = false

        var screenBrightness: CGFloat = UserDefaultManager.bright
        var totalCoin = 0
        
        var todayStudyTime: Int = 0
    }
    
    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        case .viewDidLoadTrigger(let brightNess):
            UserDefaultManager.stopCount = 3
            UserDefaultManager.bright = brightNess
            let user = userUseCase.excuteFetchUser()
            
            //CoinTest용
//            coinUseCase.excuteCreateCoin(CoinEntity(id: UUID(), getCoin: 10000, spendCoin: 0, status: 1000, now: .now))
            
            if fontUseCase.excuteFetchFontTable().isEmpty {
                fontUseCase.excuteFirstStartFont(fontName: FontThema.UhBeeFont.rawValue, purcase: true)
                fontUseCase.excuteFirstStartFont(fontName: FontThema.GangwonFont.rawValue, purcase: false)
                fontUseCase.excuteFirstStartFont(fontName: FontThema.LeeSeoyunFont.rawValue, purcase: false)
                fontUseCase.excuteFirstStartFont(fontName: FontThema.SimKyunghaFont.rawValue, purcase: false)
            }
            
            if themaUseCase.excuteFetchThemaTable().isEmpty {
                themaUseCase.excuteFirstStartThema(themaName: Thema.SeSACThema.rawValue, purcase: true)
                themaUseCase.excuteFirstStartThema(themaName: Thema.PurpleThema.rawValue, purcase: false)
                themaUseCase.excuteFirstStartThema(themaName: Thema.PinkThema.rawValue, purcase: false)
                themaUseCase.excuteFirstStartThema(themaName: Thema.NightThema.rawValue, purcase: false)
                themaUseCase.excuteFirstStartThema(themaName: Thema.BeachThema.rawValue, purcase: false)
            }
            return .concat([.just(.getTotalCoin(coinUseCase.excuteTotalCoin())), .just(.userData(user))])
            
        case .timerButtonTapped:
            if currentState.isTimerRunning {
                // 타이머 중지 로직
                if UserDefaultManager.stopCount > 0 {
                    // 중지 기회가 남아있음
                    timer?.dispose()
                    timer = nil
                    
                    let stopChance = UserDefaultManager.stopCount - 1
                    UserDefaultManager.stopCount = stopChance
                    UserDefaultManager.timerRunning = false

                    return .concat([
                        .just(.setTimerButtonState(false)),
                        .just(.setButtonTitle("시작")),
                        .just(.stopChance(stopChance))
                    ])
                } else {
                    // 중지 기회가 없음 - 토스트 메시지
                    return .concat([
                        .just(.showToast("멈출 수 있는 기회를 다 써버렸어요 😣")),
                        .just(.clearToastMessage).delay(.seconds(3), scheduler: MainScheduler.instance)
                    ])
                    
                }
            } else {
                // 타이머 시작 로직
                if currentState.firstStartButtonClicked {
                    // 필요한 경우 저장소 로직 추가
                    userUseCase.excuteAddUser(settingTime: UserDefaultManager.engagedTime)
                }
                
                UserDefaultManager.timerRunning = true
                
                // 타이머 Observable 생성 - 1초마다 업데이트
                timer?.dispose() // 기존 타이머가 있다면 해제
                
                // 타이머 로직 수정 - Action을 직접 전달
//                timer = Observable<Int>.interval(.seconds(1), scheduler: MainScheduler.instance)
                timer = Observable<Int>.interval(.milliseconds(10), scheduler: MainScheduler.instance)
                    .subscribe(onNext: { [weak self] _ in
                        guard let self = self else { return }
                        
                        if self.currentState.remainingTime > 0 {
                            self.action.onNext(.timerTick)
                        } else {
                            self.action.onNext(.timerCompleted)
                        }
                    })
                
                return .concat([
                    .just(.setTimerButtonState(true)),
                    .just(.setButtonTitle("중지"))
                ])
            }
            
        case .timerTick:
            let newRemainingTime = currentState.remainingTime - 1
            let progress = Float(newRemainingTime) / Float(currentState.totalTime)
            
            if newRemainingTime <= 0 {
                return .concat([
                    .just(.updateRemainingTime(newRemainingTime)),
                    .just(.updateProgress(1.0 - progress)),
                    .just(.navigateToFinishPopup(true)),
                    .just(.navigateToFinishPopup(false)).delay(.milliseconds(100), scheduler: MainScheduler.instance)
                ])
            } else {
                return .concat([
                    .just(.updateRemainingTime(newRemainingTime)),
                    .just(.updateProgress(1.0 - progress))
                ])
            }
            
        case .timerCompleted:
            timer?.dispose()
            timer = nil
            
            UserDefaultManager.timerRunning = false
            return .concat([
                .just(.setTimerButtonState(false)),
                .just(.setButtonTitle("완료")),
                .just(.resetTimer)
            ])
        case .calendarButtonTapped:
            return .concat([
                .just(.navigateToCalendar(true)),
                .just(.navigateToCalendar(false)).delay(.milliseconds(100), scheduler: MainScheduler.instance)
            ])
            
        case .settingButtonTapped:
            return .concat([
                .just(.navigateToSetting(true)),
                .just(.navigateToSetting(false)).delay(.milliseconds(100), scheduler: MainScheduler.instance)
            ])
            
        case .bulbButtonTapped:
            return .just(.toggleBulb)
            
        case .timeLineButtonTapped:
            return .concat([
                .just(.navigateToTimeLine(true)),
                .just(.navigateToTimeLine(false)).delay(.milliseconds(100), scheduler: MainScheduler.instance)
            ])
        }
    }
    
    func reduce(state: State, mutation: Mutation) -> State {
        var newState = state
        
        switch mutation {
        case .setTimerButtonState(let isRunning):
            newState.isTimerRunning = isRunning
            
        case .updateRemainingTime(let time):
            newState.remainingTime = time
            
            print(time)
            // 시간이 0이면 타이머 완료 처리
            if time <= 0 {
                newState.buttonTitle = "완료"
                newState.isTimerRunning = false
                newState.firstStartButtonClicked = true
                
                timer?.dispose()
                timer = nil
                UserDefaultManager.timerRunning = false
                // 기본값으로 재설정
                newState.remainingTime = newState.totalTime
            }
            
        case .updateProgress(let progress):
            newState.progress = progress
            
        case .setButtonTitle(let title):
            newState.buttonTitle = title
            
        case .resetTimer:
            newState.remainingTime = newState.totalTime
            newState.progress = 0.0
            
        case .finishTimer:
            newState.buttonTitle = "완료"
            newState.isTimerRunning = false
            newState.firstStartButtonClicked = true
            
            // 기본값으로 재설정
            newState.remainingTime = newState.totalTime
            
        case .showToast(let message):
            newState.toastMessage = message
        case .stopChance(let chance):
            newState.stopChances = chance
        case .navigateToCalendar(let navigate):
            newState.totalCoin = coinUseCase.excuteTotalCoin()
            newState.shouldNavigateToCalendar = navigate
            return newState
            
        case .navigateToSetting(let navigate):
            newState.shouldNavigateToSetting = navigate
            return newState
        case .toggleBulb:
            newState.shouldToggleBulb.toggle()
            if newState.shouldToggleBulb {
                newState.screenBrightness = 0
            } else {
                newState.screenBrightness = UserDefaultManager.bright
            }
            return newState
            
        case .navigateToTimeLine(let navigate):
            newState.shouldNavigateToTimeLine = navigate
            return newState
        case .clearToastMessage:
            newState.toastMessage = nil
        case .getTotalCoin(let coin):
            if coin == 0 {
                coinUseCase.excuteCreateCoin(CoinEntity(id: UUID(), getCoin: 100, spendCoin: 0, status: 100, now: .now))
                newState.totalCoin = 100
            } else {
                newState.totalCoin = coin
            }
            return newState
        case .userData(let useData):
            if userUseCase.excuteTodayTotalStudyTime().isEmpty {
                newState.todayStudyTime = 0
            } else {
                for i in 0...userUseCase.excuteTodayTotalStudyTime().count-1 {
                    var totalStudyTime = 0
                    totalStudyTime += userUseCase.excuteTodayTotalStudyTime()[i].settingTime
                    newState.todayStudyTime = totalStudyTime
                }
                return newState
            }
        case .navigateToFinishPopup(let navigate):
            newState.shouldNavigateToFinishPopup = navigate
        }
        
        return newState
    }
}
