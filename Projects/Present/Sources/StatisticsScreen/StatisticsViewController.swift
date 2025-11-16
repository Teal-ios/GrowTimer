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
    
    private func updateChartAndSuccessRate(period: Int, allUserData: [UserEntity]) {
        guard let chartPeriod = ChartPeriod(rawValue: period) else { return }
        
        let (chartData, totalAttempts, successfulAttempts) = processData(for: chartPeriod, allUserData: allUserData)
        
        let rawMax = chartData.map { $0.rawValue }.max() ?? 0.0
        

        var chartYAxisMax: Double
        
        if rawMax <= 0 {
            chartYAxisMax = 10.0
        } else if period == ChartPeriod.daily.rawValue {
            let ceilingValue = ceil(rawMax / 10.0) * 10.0
            chartYAxisMax = max(ceilingValue, 10.0) // 최소 10분 보장
        } else {
            let rawMaxHours = rawMax / 60.0
            let ceilingHours = ceil(rawMaxHours)
            let ceilingMinutes = ceilingHours * 60.0
            chartYAxisMax = max(ceilingMinutes, 60.0)
        }
        
        let normalizedData = chartData.map { item in
            let normalizedValue = item.rawValue / chartYAxisMax
            return BarChartData(label: item.label, value: normalizedValue, rawValue: item.rawValue)
        }
        
        statisticsView.barChartView.updateChart(with: normalizedData, rawMax: chartYAxisMax, mode: period)
        
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
            let hours = Array(stride(from: 0, to: 24, by: 2))
            labels = hours.map { "\($0)시" }
            
            let today = calendar.startOfDay(for: Date())
            let dailySuccessfulData = allUserData.filter {
                calendar.isDate($0.startTime, inSameDayAs: today) && $0.success
            }
            
            for entity in dailySuccessfulData {
                
                let hour = calendar.component(.hour, from: entity.startTime)
                let key = "\((hour / 2) * 2)시"
                
                let duration = Double(entity.settingTime) / 60.0 // 분 단위
                rawData[key, default: 0] += duration
            }
            
            let outputData = labels.map { label -> (String, Double) in
                return (label, rawData[label] ?? 0)
            }
            return (outputData, totalAttempts, successfulAttempts)
            
        case .weekly:
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "ko_KR")
            dateFormatter.dateFormat = "E"
            
            var dayMap: [Date: String] = [:]
            var sevenDays: [Date] = []
            
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
                guard entity.success else { continue }
                
                let startDay = calendar.startOfDay(for: entity.startTime)
                
                if sevenDays.contains(startDay), let label = dayMap[startDay] {
                    let duration = Double(entity.settingTime) / 60.0
                    rawData[label, default: 0] += duration
                }
            }
            
            let outputData = labels.map { label -> (String, Double) in
                // rawValue: 분 단위
                return (label, rawData[label] ?? 0)
            }
            return (outputData, totalAttempts, successfulAttempts)
            
        case .monthly:
            let months: [String] = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
            labels = months
            
            let startOfCurrentYear = calendar.date(from: calendar.dateComponents([.year], from: Date()))!
            
            for entity in allUserData {
                guard entity.success,
                        entity.startTime >= startOfCurrentYear else { continue }
                
                let monthIndex = calendar.component(.month, from: entity.startTime) - 1 // 0-11
                let key = months[monthIndex]
                
                let duration = Double(entity.settingTime) / 60.0 // 분 단위
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
