//
//  DIContainer.swift
//  Utility
//
//  Created by Den on 4/28/25.
//  Copyright © 2025 Den. All rights reserved.
//

import Foundation

public enum DIContainer {
    private static var storage = [String: () -> Any]()
    private static var cachedInstances = [String: Any]()
    
    public static func register<T>(_ type: T.Type, _ factory: @escaping @autoclosure () -> T) {
        storage["\(type)"] = factory
        cachedInstances.removeValue(forKey: "\(type)")
    }
    
    @discardableResult
    public static func resolve<T>(type: T.Type) -> T {
        let key = "\(type)"
        
        if let cachedInstance = cachedInstances[key] as? T {
            return cachedInstance
        }
        
        guard let factory = storage[key], let newInstance = factory() as? T else {
            fatalError("등록되지 않은 객체 호출: \(type)")
        }
        
        cachedInstances[key] = newInstance
        
        return newInstance
    }
}

extension DIContainer {
    public static var originalStorage: [String: () -> Any] = [:]
    
    public static func setupForTesting() {
        // 원본 저장소 백업
        originalStorage = storage
        // 테스트용 빈 저장소로 초기화
        storage = [:]
    }
    
    public static func tearDownTesting() {
        // 원본 저장소 복원
        storage = originalStorage
        cachedInstances = [:] // 캐시된 인스턴스도 초기화
        originalStorage = [:]
    }
}
