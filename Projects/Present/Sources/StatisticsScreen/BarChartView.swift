//
//  BarChartView.swift
//  Present
//
//  Created by Den on 11/16/25.
//  Copyright © 2025 Den. All rights reserved.
//

import UIKit

import Utility
import DesignSystem

import SnapKit

// MARK: - Bar Chart Data Structure
struct BarChartData {
    let label: String
    let value: Double
    let rawValue: Double
}

final class CustomBarChartView: UIView {
    
    // MARK: Properties
    private let barContainerView = UIStackView()
    private let xAxisLabelContainer = UIStackView()
    private let padding: CGFloat = 20
    private let barColor = ThemaManager.shared.progressColor
    
    private var rawYAxisMax: Double = 1.0
    private var currentMode: Int = 0
    // MARK: Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupChartComponents()
        self.backgroundColor = ThemaManager.shared.mainColor
        self.layer.cornerRadius = 20
        self.layer.masksToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Setup
    private func setupChartComponents() {
        barContainerView.axis = .horizontal
        barContainerView.distribution = .fillEqually
        barContainerView.alignment = .bottom
        barContainerView.spacing = 8
        self.addSubview(barContainerView)
        
        xAxisLabelContainer.axis = .horizontal
        xAxisLabelContainer.distribution = .fillEqually
        xAxisLabelContainer.alignment = .center
        xAxisLabelContainer.spacing = 8
        self.addSubview(xAxisLabelContainer)

        barContainerView.snp.makeConstraints { make in
            make.top.equalTo(self.safeAreaLayoutGuide).offset(padding)
            make.leading.equalTo(self.safeAreaLayoutGuide).offset(padding * 2)
            make.trailing.equalTo(self.safeAreaLayoutGuide).offset(-padding)
            make.bottom.equalTo(self.safeAreaLayoutGuide).offset(-padding * 2)
        }
        
        xAxisLabelContainer.snp.makeConstraints { make in
            make.leading.trailing.equalTo(barContainerView)
            make.top.equalTo(barContainerView.snp.bottom).offset(4)
            make.height.equalTo(20)
        }
    }
    
    // MARK: Data Binding
    func updateChart(with newData: [BarChartData], rawMax: Double, mode: Int) {
        self.rawYAxisMax = rawMax
        self.currentMode = mode
        print("CustomChartData",newData)
        
        barContainerView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        xAxisLabelContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for item in newData {
            let displayValue = max(0.001, item.value)
            let barView = createBarView(value: displayValue)
            barContainerView.addArrangedSubview(barView)
            
            barView.snp.makeConstraints { make in
                make.height.equalTo(barContainerView.snp.height)
            }
            
            let label = createXAxisLabel(text: item.label)
            xAxisLabelContainer.addArrangedSubview(label)
        }
        
        self.layoutIfNeeded()
        self.setNeedsDisplay()
    }
    
    private func createBarView(value: Double) -> UIView {
        let container = UIView()
        
        let bar = UIView()
        bar.backgroundColor = self.barColor
        bar.layer.cornerRadius = 4
        bar.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        
        container.addSubview(bar)
        
        bar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(value)
        }
        
        return container
    }
    
    private func createXAxisLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        return label
    }

    private func formatYAxisValue(_ rawMinuteValue: Double) -> String {
        let formatter = NumberFormatter()
        var displayValue = rawMinuteValue

        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        
        formatter.roundingMode = .halfUp

        // currentMode: 0=일별(분), 1=주별(시간), 2=월별(시간)
        if self.currentMode == 1 || self.currentMode == 2 {
            displayValue = rawMinuteValue / 60.0
        }
        

        if displayValue < 0.0001 {
            return "0"
        }
        
        return formatter.string(from: NSNumber(value: displayValue)) ?? "0"
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let chartRect = barContainerView.frame // 막대가 그려지는 영역
        let lineColor = UIColor.white.cgColor
        let labelColor = UIColor.white
        let labelFont = UIFont.systemFont(ofSize: 10)
        
        // 1. X축 및 Y축 라인 그리기
        context.setStrokeColor(lineColor)
        context.setLineWidth(1.0)
        
        // X-Axis Line (차트 영역 하단)
        context.move(to: CGPoint(x: chartRect.minX, y: chartRect.maxY))
        context.addLine(to: CGPoint(x: chartRect.maxX, y: chartRect.maxY))
        context.strokePath()
        
        // Y-Axis Line (차트 영역 좌측)
        context.move(to: CGPoint(x: chartRect.minX, y: chartRect.maxY))
        context.addLine(to: CGPoint(x: chartRect.minX, y: chartRect.minY))
        context.strokePath()
        
        // 2. Y축 레이블 및 수평 격자선 그리기 (5개의 간격)
        let numSegments: CGFloat = 5
        
        for i in 0...Int(numSegments) {
            let normalizedValue = CGFloat(i) / numSegments
            let y = chartRect.maxY - (chartRect.height * normalizedValue)
            
            // 수평 격자선 그리기
            context.setStrokeColor(UIColor.white.withAlphaComponent(0.3).cgColor)
            context.setLineWidth(0.5)
            
            context.move(to: CGPoint(x: chartRect.minX, y: y))
            context.addLine(to: CGPoint(x: chartRect.maxX, y: y))
            context.strokePath()
            
            let rawValue = rawYAxisMax * Double(normalizedValue)
            let labelText = formatYAxisValue(rawValue)
            
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: labelFont,
                .foregroundColor: labelColor
            ]
            let labelSize = labelText.size(withAttributes: labelAttributes)
            
            let labelOriginX = chartRect.minX - labelSize.width - 5
            let labelOriginY = y - (labelSize.height / 2)
            
            labelText.draw(at: CGPoint(x: labelOriginX, y: labelOriginY), withAttributes: labelAttributes)
        }
        

        let unitText: String
        switch self.currentMode {
        case 0: // 일별
            unitText = "분"
        case 1, 2: // 주별, 월별
            unitText = "시간"
        default:
            unitText = "분"
        }
        
        let legendText = "■ 집중 시간 (단위: \(unitText))"
        
        let legendAttributes: [NSAttributedString.Key: Any] = [
            .font: labelFont,
            .foregroundColor: labelColor
        ]
        let legendSize = legendText.size(withAttributes: legendAttributes)
        
        let legendY = rect.maxY - 5 // X축 레이블 아래
        let legendX = chartRect.minX
        
        // 색상 상자 (범례 아이콘)
        let boxRect = CGRect(x: legendX, y: legendY - 10, width: 8, height: 8)
        context.setFillColor(self.barColor.cgColor)
        context.fill(boxRect)
        
        // 텍스트
        legendText.draw(at: CGPoint(x: legendX + 12, y: legendY - legendSize.height), withAttributes: legendAttributes)
    }
}
