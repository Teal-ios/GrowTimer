//
//  UserUseCaseTests.swift
//  DomainTests
//
//  Created by Den on 5/10/25.
//  Copyright © 2025 Den. All rights reserved.
//

import Foundation

import Utility

import XCTest
@testable import Domain

class UserUseCaseTests: XCTestCase {
    
    var sut: UserUseCase!

    var mockRepository: MockUserRepository!

    override func setUp() {
        super.setUp()
        
        self.mockRepository = MockUserRepository()
        self.sut = DefaultUserUseCase(repository: self.mockRepository)
        DIContainer.register(UserRepository.self, mockRepository)
    }
    
    override func tearDown() {
        DIContainer.tearDownTesting()
        sut = nil
        mockRepository = nil
        super.tearDown()
    }
    
    func testExcuteFetchUser() {
        // Arrange
        let testUser = UserEntity(
            id: UUID(),
            startTime: Date(),
            settingTime: 60,
            success: true,
            concentrateMode: false,
            stopButtonClicked: 0
        )
        mockRepository.fetchUserReturnValue = [testUser]
        
        // Act
        let result = sut.excuteFetchUser()
        
        // Assert
        XCTAssertTrue(mockRepository.fetchUserCalled)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].id, testUser.id)
    }
    
    func testExcuteAddUser() {
        // Arrange
        let settingTime = 30
        
        // Act
        sut.excuteAddUser(settingTime: settingTime)
        
        // Assert
        XCTAssertTrue(mockRepository.addUserCalled)
        XCTAssertEqual(mockRepository.addUserSettingTime, settingTime)
    }
    
    func testExcuteUpdateUserState() {
        // Arrange
        let id = UUID()
        let success = true
        
        // Act
        sut.excuteUpdateUserState(id: id, success: success)
        
        // Assert
        XCTAssertTrue(mockRepository.updateUserStateCalled)
        XCTAssertEqual(mockRepository.updateUserStateId, id)
        XCTAssertEqual(mockRepository.updateUserStateSuccess, success)
    }
    
    func testExcuteYesterdayUserFilter() {
        // Arrange
        let testUser = UserEntity(
            id: UUID(),
            startTime: Date().addingTimeInterval(-86400),
            settingTime: 60,
            success: true,
            concentrateMode: false,
            stopButtonClicked: 0
        )
        mockRepository.yesterdayFilterReturnValue = [testUser]
        
        // Act
        let result = sut.excuteYesterdayUserFilter()
        
        // Assert
        XCTAssertTrue(mockRepository.yesterdayFilterCalled)
        XCTAssertEqual(result.count, 1)
    }
    
    func testExcuteTodayTotalStudyTime() {
        // Arrange
        let testUser = UserEntity(
            id: UUID(),
            startTime: Date(),
            settingTime: 60,
            success: true,
            concentrateMode: false,
            stopButtonClicked: 0
        )
        mockRepository.todayTotalStudyTimeReturnValue = [testUser]
        
        // Act
        let result = sut.excuteTodayTotalStudyTime()
        
        // Assert
        XCTAssertTrue(mockRepository.todayTotalStudyTimeCalled)
        XCTAssertEqual(result.count, 1)
    }
    
    func testExcuteSpecificDateStudyTime() {
        // Arrange
        let date = Date()
        let testUser = UserEntity(
            id: UUID(),
            startTime: date,
            settingTime: 60,
            success: true,
            concentrateMode: false,
            stopButtonClicked: 0
        )
        mockRepository.dayTotalStudyTimeReturnValue = [testUser]
        
        // Act
        let result = sut.excuteSpecificDateStudyTime(date: date)
        
        // Assert
        XCTAssertTrue(mockRepository.dayTotalStudyTimeCalled)
        XCTAssertEqual(mockRepository.dayTotalStudyTimeDate, date)
        XCTAssertEqual(result.count, 1)
    }
    
    func testExcuteTodayFilter() {
        // Arrange
        let testUser = UserEntity(
            id: UUID(),
            startTime: Date(),
            settingTime: 60,
            success: true,
            concentrateMode: false,
            stopButtonClicked: 0
        )
        mockRepository.todayFilterReturnValue = [testUser]
        
        // Act
        let result = sut.excuteTodayFilter()
        
        // Assert
        XCTAssertTrue(mockRepository.todayFilterCalled)
        XCTAssertEqual(result.count, 1)
    }
    
    func testExcuteSpecificDateFilter() {
        // Arrange
        let date = Date()
        let testUser = UserEntity(
            id: UUID(),
            startTime: date,
            settingTime: 60,
            success: true,
            concentrateMode: false,
            stopButtonClicked: 0
        )
        mockRepository.dayFilterReturnValue = [testUser]
        
        // Act
        let result = sut.excuteSpecificDateFilter(date: date)
        
        // Assert
        XCTAssertTrue(mockRepository.dayFilterCalled)
        XCTAssertEqual(mockRepository.dayFilterDate, date)
        XCTAssertEqual(result.count, 1)
    }
    
    func testExcuteTwoHoursFilter() {
        // Arrange
        let date = Date()
        let testUser = UserEntity(
            id: UUID(),
            startTime: date,
            settingTime: 60,
            success: true,
            concentrateMode: false,
            stopButtonClicked: 0
        )
        mockRepository.twoHourTimeFilterReturnValue = [testUser]
        
        // Act
        let result = sut.excuteTwoHoursFilter(date: date)
        
        // Assert
        XCTAssertTrue(mockRepository.twoHourTimeFilterCalled)
        XCTAssertEqual(mockRepository.twoHourTimeFilterDate, date)
        XCTAssertEqual(result.count, 1)
    }
    
    func testExcuteDayTotalTimeFilter() {
        // Arrange
        let date = Date()
        let expectedTime = 120
        mockRepository.dayTotalTimeFilterReturnValue = expectedTime
        
        // Act
        let result = sut.excuteDayTotalTimeFilter(date: date)
        
        // Assert
        XCTAssertTrue(mockRepository.dayTotalTimeFilterCalled)
        XCTAssertEqual(mockRepository.dayTotalTimeFilterDate, date)
        XCTAssertEqual(result, expectedTime)
    }
    
    func testDayTotalTimeLineFilter() {
        // Arrange
        let date = Date()
        let expectedTime = 180
        mockRepository.dayTotalTimeLineFilterReturnValue = expectedTime
        
        // Act
        let result = sut.dayTotalTimeLineFilter(date: date)
        
        // Assert
        XCTAssertTrue(mockRepository.dayTotalTimeLineFilterCalled)
        XCTAssertEqual(mockRepository.dayTotalTimeLineFilterDate, date)
        XCTAssertEqual(result, expectedTime)
    }
    
    func testMonthTotalTimeFilter() {
        // Arrange
        let date = Date()
        let expectedTime = 4000
        mockRepository.monthTotalTimeFilterReturnValue = expectedTime
        
        // Act
        let result = sut.monthTotalTimeFilter(date: date)
        
        // Assert
        XCTAssertTrue(mockRepository.monthTotalTimeFilterCalled)
        XCTAssertEqual(mockRepository.monthTotalTimeFilterDate, date)
        XCTAssertEqual(result, expectedTime)
    }
    
    func testMonthCount() {
        // Arrange
        let date = Date()
        let expectedCount = 30
        mockRepository.monthCountReturnValue = expectedCount
        
        // Act
        let result = sut.monthCount(date: date)
        
        // Assert
        XCTAssertTrue(mockRepository.monthCountCalled)
        XCTAssertEqual(mockRepository.monthCountDate, date)
        XCTAssertEqual(result, expectedCount)
    }
    
    func testSuccessfulRate() {
        // Arrange
        let expectedRate = 75
        mockRepository.successfulRateReturnValue = expectedRate
        
        // Act
        let result = sut.successfulRate()
        
        // Assert
        XCTAssertTrue(mockRepository.successfulRateCalled)
        XCTAssertEqual(result, expectedRate)
    }
}
