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
    let label: String // X축 레이블 (e.g., "0시", "월")
    let value: Double // 차트 높이를 결정하는 정규화된 값 (0.0 ~ 1.0)
    let rawValue: Double // Y축 레이블에 표시할 실제 값 (항상 '분' 단위로 가정)
}

final class CustomBarChartView: UIView {
    
    // MARK: Properties
    private let barContainerView = UIStackView()
    private let xAxisLabelContainer = UIStackView()
    private let padding: CGFloat = 20
    private let barColor = ThemaManager.shared.progressColor // 대비를 위해 accentColor 사용
    
    private var rawYAxisMax: Double = 1.0 // Y축 눈금의 최댓값 (항상 분 단위)
    private var currentMode: Int = 0 // ⭐️ 현재 차트 모드 (0:일, 1:주, 2:월)를 저장하여 단위 변환에 사용
    
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
        // 1. 막대 컨테이너 (막대 뷰들을 수평으로 배치)
        barContainerView.axis = .horizontal
        barContainerView.distribution = .fillEqually
        barContainerView.alignment = .bottom
        barContainerView.spacing = 8
        self.addSubview(barContainerView)
        
        // 2. X축 레이블 컨테이너 (레이블을 수평으로 배치)
        xAxisLabelContainer.axis = .horizontal
        xAxisLabelContainer.distribution = .fillEqually
        xAxisLabelContainer.alignment = .center
        xAxisLabelContainer.spacing = 8
        self.addSubview(xAxisLabelContainer)

        // 제약 조건 설정 (SnapKit 사용)
        barContainerView.snp.makeConstraints { make in
            make.top.equalTo(self.safeAreaLayoutGuide).offset(padding)
            make.leading.equalTo(self.safeAreaLayoutGuide).offset(padding * 2) // Y축 레이블 공간
            make.trailing.equalTo(self.safeAreaLayoutGuide).offset(-padding)
            make.bottom.equalTo(self.safeAreaLayoutGuide).offset(-padding * 2) // X축 레이블 공간
        }
        
        xAxisLabelContainer.snp.makeConstraints { make in
            make.leading.trailing.equalTo(barContainerView)
            make.top.equalTo(barContainerView.snp.bottom).offset(4)
            make.height.equalTo(20)
        }
    }
    
    // MARK: Data Binding
    // ⭐️ 시그니처 변경: mode 파라미터 타입을 Int로 변경 (0:일, 1:주, 2:월)
    func updateChart(with newData: [BarChartData], rawMax: Double, mode: Int) {
        self.rawYAxisMax = rawMax
        self.currentMode = mode // ⭐️ 현재 모드 저장
        print("CustomChartData",newData)
        
        // 1. 기존 뷰 제거
        barContainerView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        xAxisLabelContainer.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // 2. 새 막대와 레이블 추가
        for item in newData {
            // 값이 0일 경우에도 최소 높이(0.001)를 부여하여 시각적인 라인을 유지합니다.
            let displayValue = max(0.001, item.value)
            let barView = createBarView(value: displayValue) // 정규화된 값(0~1) 사용
            barContainerView.addArrangedSubview(barView)
            
            // ⭐️ StackView의 alignment가 .bottom일 때 높이를 강제합니다.
            barView.snp.makeConstraints { make in
                make.height.equalTo(barContainerView.snp.height)
            }
            
            let label = createXAxisLabel(text: item.label)
            xAxisLabelContainer.addArrangedSubview(label)
        }
        
        // 3. 레이아웃을 즉시 갱신하여 막대 높이를 강제 계산합니다.
        self.layoutIfNeeded()
        
        // 4. 축과 눈금선 다시 그리기 (draw(_:) 호출)
        self.setNeedsDisplay()
    }
    
    // MARK: Bar and Label Factories
    private func createBarView(value: Double) -> UIView {
        let container = UIView()
        
        // 실제 색상 막대 뷰
        let bar = UIView()
        bar.backgroundColor = self.barColor
        bar.layer.cornerRadius = 4
        bar.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner] // 상단 모서리만 둥글게
        
        container.addSubview(bar)
        
        // 막대의 높이는 정규화된 값에 비례하여 설정
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

    // ⭐️ 개선: 차트 모드에 따라 Y축 값을 분 또는 시간으로 변환하고, 정수로 포맷팅합니다.
    private func formatYAxisValue(_ rawMinuteValue: Double) -> String {
        let formatter = NumberFormatter()
        var displayValue = rawMinuteValue // 기본은 분 단위

        // 1. 소수점 자릿수를 0으로 설정하여 정수만 표시하도록 강제합니다.
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 0
        
        // 2. 반올림 모드를 설정하여 0.5 이상일 때 다음 정수로 올림 처리합니다.
        formatter.roundingMode = .halfUp

        // currentMode: 0=일별(분), 1=주별(시간), 2=월별(시간)
        if self.currentMode == 1 || self.currentMode == 2 {
            // 주/월별 모드: 시간(Hour)으로 변환
            displayValue = rawMinuteValue / 60.0
        }
        
        // 3. 최종 정수로 변환하여 반환
        // 값이 0에 가까우면 "0"을 반환
        if displayValue < 0.0001 {
            return "0"
        }
        
        // 4. NSNumber를 사용하여 반올림된 정수 문자열을 얻습니다.
        return formatter.string(from: NSNumber(value: displayValue)) ?? "0"
    }

    // MARK: Custom Drawing (Core Graphics로 축 및 눈금선 그리기)
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
            
            // Y축 레이블 그리기
            let rawValue = rawYAxisMax * Double(normalizedValue) // 실제 값 (항상 분 단위)
            let labelText = formatYAxisValue(rawValue) // ⭐️ 모드에 따라 시간/분으로 변환된 값 (정수형)
            
            let labelAttributes: [NSAttributedString.Key: Any] = [
                .font: labelFont,
                .foregroundColor: labelColor
            ]
            let labelSize = labelText.size(withAttributes: labelAttributes)
            
            // Y축 왼쪽으로 위치 조정
            let labelOriginX = chartRect.minX - labelSize.width - 5
            let labelOriginY = y - (labelSize.height / 2)
            
            // 차트 뷰의 Bounds 내에 레이블을 그립니다.
            labelText.draw(at: CGPoint(x: labelOriginX, y: labelOriginY), withAttributes: labelAttributes)
        }
        
        // 3. 범례(Legend) 그리기
        // ⭐️ 현재 모드에 따라 범례의 단위 텍스트를 변경합니다.
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
