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

    }
    
    // MARK: UI Configuration and Binding
    // MARK: Core Logic
    
    private func updateChartAndSuccessRate(period: Int, allUserData: [UserEntity]) {
        guard let chartPeriod = ChartPeriod(rawValue: period) else { return } // 🚨 '같다. }' 대신 'return'으로 수정
        
        // chartData의 rawValue는 항상 '분' 단위입니다.
        let (chartData, totalAttempts, successfulAttempts) = processData(for: chartPeriod, allUserData: allUserData)
        
        // 1. 차트 데이터 업데이트
        
        // Y축 최댓값 (실제 raw value 중 최댓값, 단위: 분) 계산
        let rawMax = chartData.map { $0.rawValue }.max() ?? 0.0
        
        // ⭐️ 핵심 로직: Y축 레이블이 깨지는 것을 방지하기 위해 최대값(chartYAxisMax)을 정돈된 값으로 설정
        var chartYAxisMax: Double
        
        if rawMax <= 0 {
            // 데이터가 없으면 최소값 설정 (예: 10분)
            chartYAxisMax = 10.0
        } else if period == ChartPeriod.daily.rawValue {
            // 일별(분 단위): 최대값을 10의 배수로 올림 (예: 35분 -> 40분, 120분 -> 120분)
            let ceilingValue = ceil(rawMax / 10.0) * 10.0
            chartYAxisMax = max(ceilingValue, 10.0) // 최소 10분 보장
        } else {
            // 주/월별(시간 단위): 최대값을 정수 시간으로 올림 후 다시 '분'으로 변환
            // (예: 1.5시간(90분) -> 2시간(120분)으로 올림)
            let rawMaxHours = rawMax / 60.0 // 최대값을 시간으로 변환
            let ceilingHours = ceil(rawMaxHours)
            let ceilingMinutes = ceilingHours * 60.0
            chartYAxisMax = max(ceilingMinutes, 60.0) // 최소 1시간(60분) 보장
        }
        
        // ⭐️ 정규화: 계산된 chartYAxisMax (분 단위)를 사용하여 0.0 ~ 1.0으로 정규화
        let normalizedData = chartData.map { item in
            // item.rawValue는 실제 집중 시간(분)
            let normalizedValue = item.rawValue / chartYAxisMax
            return BarChartData(label: item.label, value: normalizedValue, rawValue: item.rawValue)
        }
        
        // CustomBarChartView에 '분' 단위의 최종 최대값(chartYAxisMax)과 모드(0, 1, 2) 전달
        statisticsView.barChartView.updateChart(with: normalizedData, rawMax: chartYAxisMax, mode: period)
        
        // 2. 성공률 레이블 업데이트
        let successRate: Double = totalAttempts > 0 ? (Double(successfulAttempts) / Double(totalAttempts)) * 100 : 0
        statisticsView.sucessfulLabel.text = String(format: "집중 성공률: %.1f%%", successRate)
    }
    
    
    private func processData(for period: ChartPeriod, allUserData: [UserEntity]) -> (chartData: [(label: String, rawValue: Double)], total: Int, success: Int) {
        
        print(allUserData)
        let calendar = Calendar.current
        var rawData: [String: Double] = [:]
        var labels: [String] = []
        
        // 전체 성공/시도 횟수 계산 (전체 데이터셋 기준)
        let totalAttempts = allUserData.count
        let successfulAttempts = allUserData.filter { $0.success }.count
        
        switch period {
        case .daily:
            // 일별: 오늘 하루 성공 세션 시작 시간대별 집중 시간 (분)
            let hours = Array(stride(from: 0, to: 24, by: 2))
            labels = hours.map { "\($0)시" }
            
            let today = calendar.startOfDay(for: Date())
            // 오늘 성공한 세션만 필터링
            let dailySuccessfulData = allUserData.filter {
                // Timezone이 KST일 경우, +0000 UTC로 저장된 시간이 현재 날짜에 맞게 변환됩니다.
                calendar.isDate($0.startTime, inSameDayAs: today) && $0.success
            }
            
            for entity in dailySuccessfulData {
                // 🚨 수정: 성공 세션은 settingTime을 사용하므로 finishTime 체크 불필요
                
                let hour = calendar.component(.hour, from: entity.startTime) // 현재 Timezone 기준 시간
                let key = "\((hour / 2) * 2)시" // 0, 2, 4, ...
                
                // ⭐️ 핵심 수정: rawValue에 '분' 단위 집중 시간을 더함. (settingTime 기반)
                let duration = Double(entity.settingTime) / 60.0 // 분 단위
                rawData[key, default: 0] += duration
            }
            
            // 모든 시간대에 대한 데이터 구성 (데이터가 없으면 0)
            let outputData = labels.map { label -> (String, Double) in
                // rawValue: 분 단위
                return (label, rawData[label] ?? 0)
            }
            return (outputData, totalAttempts, successfulAttempts)
            
        case .weekly:
            // 주간: 최근 7일간의 성공 집중 시간 (분)
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "ko_KR")
            dateFormatter.dateFormat = "E" // 요일 (e.g., '월')
            
            var dayMap: [Date: String] = [:]
            var sevenDays: [Date] = []
            
            // 최근 7일 (7일 전 ~ 오늘)의 날짜와 레이블 설정 (오래된 날짜부터)
            for i in 0..<7 {
                let day = calendar.date(byAdding: .day, value: -6 + i, to: calendar.startOfDay(for: Date()))!
                let startOfDay = calendar.startOfDay(for: day)
                sevenDays.append(startOfDay)
                
                let label: String
                if calendar.isDateInToday(day) { label = "오늘" }
                else { label = dateFormatter.string(from: day) } // 요일 사용
                
                dayMap[startOfDay] = label
            }
            
            labels = sevenDays.compactMap { dayMap[$0] }
            
            for entity in allUserData {
                // 🚨 수정: 성공(true) 세션만 처리하고, 집중 시간은 settingTime을 분으로 변환하여 사용합니다.
                guard entity.success else { continue }
                
                let startDay = calendar.startOfDay(for: entity.startTime)
                
                // 7일 범위 내의 데이터만 처리
                if sevenDays.contains(startDay), let label = dayMap[startDay] {
                    // ⭐️ 핵심 수정: settingTime을 분 단위로 변환하여 사용
                    let duration = Double(entity.settingTime) / 60.0 // 분 단위
                    rawData[label, default: 0] += duration
                }
            }
            
            let outputData = labels.map { label -> (String, Double) in
                // rawValue: 분 단위
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
                // 🚨 수정: 성공(true) 세션만 처리하고, 집중 시간은 settingTime을 분으로 변환하여 사용합니다.
                guard entity.success,
                        entity.startTime >= startOfCurrentYear else { continue }
                
                let monthIndex = calendar.component(.month, from: entity.startTime) - 1 // 0-11
                let key = months[monthIndex]
                
                // ⭐️ 핵심 수정: settingTime을 분 단위로 변환하여 사용
                let duration = Double(entity.settingTime) / 60.0 // 분 단위
                rawData[key, default: 0] += duration
            }
            
            let outputData = months.map { label -> (String, Double) in
                // rawValue: 분 단위
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
            .observe(on: MainScheduler.instance)
            .bind(with: self) { owner, value in
                owner.updateChartAndSuccessRate(period: value.1, allUserData: value.0)
                print("전체 통계 데이터",value)
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
