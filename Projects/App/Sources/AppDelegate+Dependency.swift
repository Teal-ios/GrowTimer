//
//  AppDelegate+Dependency.swift
//  App
//
//  Created by Den on 4/29/25.
//  Copyright © 2025 Den. All rights reserved.
//

import Foundation

import FeatureInterface
import FeatureImplement
import Utility
import DesignSystem
import Data
import Domain

extension AppDelegate {
    func registerDependencies() {
        DIContainer.register(FeatureProvider.self, FeatureProviderImplement())
        FontRegistration.registerFonts()
        DIContainer.register(CoreDataRepository.self, CoreDataRepositoryImpl(userStorage: .userStorage, themaStorage: .themaStorage, fontStorage: .fontStorage, coinStorage: .coinStorage))
        DIContainer.register(CoreDataUseCaseInterface.self, CoreDataUseCase())
        DIContainer.register(CoinRepository.self, CoinRepositoryImpl(coinStorage: .coinStorage))
        DIContainer.register(CoinUseCaseInterface.self, CoinUseCase())
        DIContainer.register(UserRepository.self, UserRepositoryImpl(userStorage: .userStorage))
        DIContainer.register(UserUseCaseInterface.self, UserUseCase())
        DIContainer.register(FontRepository.self, FontRepositoryImpl(fontStorage: .fontStorage))
        DIContainer.register(FontUseCaseInterface.self, FontUseCase())
        
        DIContainer.register(ThemaRepository.self, ThemaRepositoryImpl(themaStorage: .themaStorage))
        DIContainer.register(ThemaUseCaseInterface.self, ThemaUseCase())
    }
}
