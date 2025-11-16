//
//  StatisticsViewController.swift
//  Present
//
//  Created by Den on 11/16/25.
//  Copyright © 2025 Den. All rights reserved.
//

import UIKit

import Utility
import ThirdPartyLibrary
import DesignSystem
import Domain

import RxSwift
import RxCocoa
import ReactorKit
import GTToast


final class StatisticsViewController: BaseViewController {
    
    // MARK: Properties
    private let statisticsView = StatisticsView()
//    private var allUserData: [UserEntity] = [] // 전체 사용자 데이터
    
    private enum ChartPeriod: Int {
        case daily = 0
        case weekly = 1
        case monthly = 2
    }

    // MARK: View Lifecycle
    
    init(reactor: StatisticsReactor) {
        super.init()
        self.reactor = reactor
    }
    
    override func loadView() {
        self.view = statisticsView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        binding()
    }
    
    // MARK: UI Configuration and Binding
    
    override func configureUI() {
        self.view.backgroundColor = ThemaManager.shared.lightColor
        self.navigationController?.navigationBar.tintColor = ThemaManager.shared.mainColor
        
        // "뒤로" 버튼 (네비게이션 컨트롤러를 사용한다고 가정)
        let backButton = UIBarButtonItem(title: "뒤로", style: .plain, target: self, action: #selector(backButtonTapped))
        navigationItem.leftBarButtonItem = backButton
    }
    
    func binding() {
        // 세그먼트 컨트롤 값 변경 액션 연결
        statisticsView.segmentedControl.addTarget(self, action: #selector(segmentedControlChanged), for: .valueChanged)
    }
    
    // MARK: Data Simulation (더미 데이터 생성)
    
//    private func simulateInitialData() {
//        let calendar = Calendar.current
//        let today = Date()
//        
//        // 최근 365일치 더미 데이터 생성
//        for i in 0..<365 {
//            let daysAgo = calendar.date(byAdding: .day, value: -i, to: today)!
//            let hour = calendar.component(.hour, from: daysAgo)
//            
//            // 간단한 성공/실패 로직
//            let success = (i % 7 != 0) // 대략 85% 성공률
//            let settingTime = success ? 60 : 30
//            
//            let entity = UserEntity(
//                id: UUID(),
//                startTime: daysAgo,
//                finishTime: daysAgo.addingTimeInterval(TimeInterval(settingTime * 60)),
//                settingTime: settingTime,
//                success: success,
//                concentrateMode: true,
//                stopButtonClicked: success ? 0 : 1
//            )
//            allUserData.append(entity)
//        }
//    }
    
    // MARK: Actions
    
    @objc private func backButtonTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func segmentedControlChanged(_ sender: UISegmentedControl) {
//        updateChartAndSuccessRate(allUserData: <#[UserEntity]#>)
    }
    
    // MARK: Core Logic
    
    private func updateChartAndSuccessRate(period: Int, allUserData: [UserEntity]) {
        guard let period = ChartPeriod(rawValue: period) else { return }
        
        let (chartData, totalAttempts, successfulAttempts) = processData(for: period, allUserData: allUserData)
        
        // 1. 차트 데이터 업데이트
        
        // Y축 최댓값 (실제 raw value 중 최댓값) 계산
        let rawMax = chartData.map { $0.rawValue }.max() ?? 1.0
        let chartYAxisMax = (rawMax > 0) ? rawMax : 1.0 // 0이면 1.0으로 설정
        
        // 차트 출력을 위한 정규화 (0.0 ~ 1.0)
        let normalizedData = chartData.map { item in
            let normalizedValue = item.rawValue / chartYAxisMax
            return BarChartData(label: item.label, value: normalizedValue, rawValue: item.rawValue)
        }
        
        statisticsView.barChartView.updateChart(with: normalizedData, rawMax: chartYAxisMax)
        
        // 2. 성공률 레이블 업데이트
        let successRate: Double = totalAttempts > 0 ? (Double(successfulAttempts) / Double(totalAttempts)) * 100 : 0
        statisticsView.sucessfulLabel.text = String(format: "집중 성공률: %.1f%%", successRate)
    }
    
    // MARK: Data Processing (주기별 통계 계산)
    
    private func processData(for period: ChartPeriod, allUserData: [UserEntity]) -> (chartData: [(label: String, rawValue: Double)], total: Int, success: Int) {
        let calendar = Calendar.current
        var rawData: [String: Double] = [:]
        var labels: [String] = []
        
        // 전체 성공/시도 횟수 계산 (전체 데이터셋 기준)
        let totalAttempts = allUserData.count
        let successfulAttempts = allUserData.filter { $0.success }.count
        
        switch period {
        case .daily:
            // 일별: 오늘 하루 성공 세션 시작 시간대별 횟수 (2시간 단위)
            let hours = Array(stride(from: 0, to: 24, by: 2))
            labels = hours.map { "\($0)시" }
            
            let today = calendar.startOfDay(for: Date())
            // 오늘 성공한 세션만 필터링
            let dailySuccessfulData = allUserData.filter {
                calendar.isDate($0.startTime, inSameDayAs: today) && $0.success
            }
            
            for entity in dailySuccessfulData {
                let hour = calendar.component(.hour, from: entity.startTime)
                let key = "\((hour / 2) * 2)시" // 0, 2, 4, ...
                rawData[key, default: 0] += 1
            }
            
            // 모든 시간대에 대한 데이터 구성 (데이터가 없으면 0)
            let outputData = labels.map { label -> (String, Double) in
                return (label, rawData[label] ?? 0)
            }
            return (outputData, totalAttempts, successfulAttempts)
            
        case .weekly:
            // 주간: 최근 7일간의 성공 집중 시간 (분)
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "ko_KR")
            dateFormatter.dateFormat = "E" // 요일 (e.g., '월')
            
            // 최근 7일 (오늘, 어제, 2일 전, ...)의 날짜와 레이블 설정
            var dayMap: [Date: String] = [:]
            var sevenDays: [Date] = []
            
            for i in 0..<7 {
                let day = calendar.date(byAdding: .day, value: -i, to: Date())!
                let startOfDay = calendar.startOfDay(for: day)
                sevenDays.append(startOfDay)
                
                let label: String
                if i == 0 { label = "오늘" }
                else if i == 1 { label = "어제" }
                else { label = "\(i)일 전" }
                
                dayMap[startOfDay] = label
            }
            sevenDays.reverse() // 오래된 날짜부터 정렬
            labels = sevenDays.compactMap { dayMap[$0] }
            
            for entity in allUserData {
                guard let finish = entity.finishTime, entity.success else { continue }
                
                let startDay = calendar.startOfDay(for: entity.startTime)
                if let label = dayMap[startDay] {
                    let duration = finish.timeIntervalSince(entity.startTime) / 60.0 // 분 단위
                    rawData[label, default: 0] += duration
                }
            }
            
            let outputData = labels.map { label -> (String, Double) in
                return (label, rawData[label] ?? 0)
            }
            return (outputData, totalAttempts, successfulAttempts)
            
        case .monthly:
            // 월별: 최근 12개월간의 성공 집중 시간 (분)
            let months: [String] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
            labels = months
            
            // 현재 연도 데이터만 필터링 (간단화)
            let startOfCurrentYear = calendar.date(from: calendar.dateComponents([.year], from: Date()))!
            
            for entity in allUserData {
                guard let finish = entity.finishTime, entity.success,
                      entity.startTime >= startOfCurrentYear else { continue }
                
                let monthIndex = calendar.component(.month, from: entity.startTime) - 1 // 0-11
                let key = months[monthIndex]
                
                let duration = finish.timeIntervalSince(entity.startTime) / 60.0 // 분 단위
                rawData[key, default: 0] += duration
            }
            
            let outputData = months.map { label -> (String, Double) in
                return (label, rawData[label] ?? 0)
            }
            return (outputData, totalAttempts, successfulAttempts)
        }
    }
    
    private func bindAction(reactor: StatisticsReactor) {
        viewDidLoadEvent
            .map { Reactor.Action.viewDidLoadTrigger }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        statisticsView.segmentedControl.rx.value
            .map { Reactor.Action.segmentControlDidChange($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
    }
    
    private func bindState(reactor: StatisticsReactor) {


        Observable.combineLatest(reactor.state.map(\.userData), reactor.state.map(\.segmentValue))
            .bind(with: self) { owner, value in
                owner.updateChartAndSuccessRate(period: value.1, allUserData: value.0)
            }
            .disposed(by: disposeBag)
    }
}

extension StatisticsViewController: View {
    func bind(reactor: StatisticsReactor) {
        bindAction(reactor: reactor)
        bindState(reactor: reactor)
    }
}
