//
//  StatisticsView.swift
//  Present
//
//  Created by Den on 11/16/25.
//  Copyright © 2025 Den. All rights reserved.
//

import UIKit

import Utility
import DesignSystem

import SnapKit

final class StatisticsView: BaseView {
    
    let bgView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemaManager.shared.lightColor
        return view
    }()
    
    // 커스텀 막대 차트 뷰 사용
    var barChartView: CustomBarChartView = {
        let view = CustomBarChartView()
        // CustomBarChartView 내에서 배경색과 둥근 모서리를 처리합니다.
        return view
    }()
    
    // containChartView는 차트 영역의 배경 및 테두리 역할을 합니다.
    var containChartView: UIView = {
        let view = UIView()
        view.backgroundColor = ThemaManager.shared.mainColor
        view.layer.cornerRadius = 20 // 둥근 모서리
        view.layer.masksToBounds = true
        return view
    }()
    
    var segmentedControl: UISegmentedControl = {
        let items = ["일", "주", "월"]
        let segmentedControl = UISegmentedControl(items: items)
        segmentedControl.selectedSegmentIndex = 0 // 기본값 '일'
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        
        // Customization
        let mainColor = ThemaManager.shared.mainColor
        segmentedControl.backgroundColor = mainColor.withAlphaComponent(0.2)
        segmentedControl.selectedSegmentTintColor = mainColor
        
        let normalTextAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: mainColor]
        let selectedTextAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.white]
        
        segmentedControl.setTitleTextAttributes(normalTextAttributes, for: .normal)
        segmentedControl.setTitleTextAttributes(selectedTextAttributes, for: .selected)
        
        return segmentedControl
    }()
    
    var sucessfulLabel: UILabel = {
        let label = UILabel()
        label.font = FontManager.shared.font36
        label.textColor = ThemaManager.shared.mainColor
        label.textAlignment = .center
        label.text = "집중 성공률: 0%"
        return label
    }()
    
    // MARK: Layout
    
    override func configureUI() {
        [bgView, segmentedControl, sucessfulLabel, containChartView].forEach {
            self.addSubview($0)
        }
        // 차트 뷰는 컨테이너 안에 추가
        containChartView.addSubview(barChartView)
    }
    
    override func configureLayout() {

        bgView.snp.makeConstraints { make in
            make.edges.equalTo(0)
        }
        
        segmentedControl.snp.makeConstraints { make in
            make.centerX.equalTo(safeAreaLayoutGuide)
            make.top.equalTo(safeAreaLayoutGuide).offset(20)
            make.width.equalTo(200)
            make.height.equalTo(30)
        }
        
        sucessfulLabel.snp.makeConstraints { make in
            make.leading.equalTo(safeAreaLayoutGuide).offset(40)
            make.trailing.equalTo(safeAreaLayoutGuide).offset(-40)
            make.bottom.equalTo(safeAreaLayoutGuide).offset(-40)
            make.height.equalTo(80)
        }
        
        containChartView.snp.makeConstraints { make in
            make.top.equalTo(segmentedControl.snp.bottom).offset(40)
            make.leading.equalTo(safeAreaLayoutGuide).offset(28)
            make.trailing.equalTo(safeAreaLayoutGuide).offset(-28)
            make.bottom.equalTo(sucessfulLabel.snp.top).offset(-28)
        }
        
        // 차트 뷰는 컨테이너에 약간의 인셋을 주어 채웁니다.
        barChartView.snp.makeConstraints { make in
            make.edges.equalTo(containChartView).inset(4)
        }
    }
}
