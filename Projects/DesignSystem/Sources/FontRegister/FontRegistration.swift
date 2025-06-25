//
//  FontRegistration.swift
//  DesignSystem
//
//  Created by Den on 4/30/25.
//  Copyright © 2025 Den. All rights reserved.
//

import UIKit

public final class FontRegistration {
    public static func registerFonts() {
        // 폰트 등록 로직
        registerFont(withFilenameString: "GwangwonEduAll-Bold.otf")
        registerFont(withFilenameString: "SimKyungha.otf")
        registerFont(withFilenameString: "LeeSeoyun.otf")
        registerFont(withFilenameString: "UhBeeBEOJJIBold.ttf")
        registerFont(withFilenameString: "UhBeeBEOJJI.ttf")
    }
    
    private static func registerFont(withFilenameString filenameString: String) {
        // 모듈 번들 우선, 메인 번들은 fallback
        let moduleBundle = Bundle.module
        let mainBundle = Bundle.main
        
        var bundleURL: URL?
        // 모듈 번들에서 먼저 찾기
        if let url = moduleBundle.url(forResource: filenameString, withExtension: nil) {
            bundleURL = url
            print("✅ 폰트 파일 모듈 번들에서 찾음: \(filenameString)")
        }
        // 메인 번들에서 찾기 (fallback)
        else if let url = mainBundle.url(forResource: filenameString, withExtension: nil) {
            bundleURL = url
            print("✅ 폰트 파일 메인 번들에서 찾음: \(filenameString)")
        }
        // URL을 찾지 못한 경우
        guard let foundURL = bundleURL else {
            print("⚠️ 폰트 파일을 찾을 수 없음: \(filenameString)")
            print("📂 모듈 번들 경로: \(moduleBundle.bundlePath)")
            print("📂 메인 번들 경로: \(mainBundle.bundlePath)")
            return
        }
        do {
            let fileManager = FileManager.default
            if !fileManager.fileExists(atPath: foundURL.path) {
                print("⚠️ 폰트 파일이 경로에 존재하지 않음: \(foundURL.path)")
                return
            }
            let fontData = try Data(contentsOf: foundURL)
            guard let fontDataProvider = CGDataProvider(data: fontData as CFData) else {
                print("⚠️ 폰트 데이터 제공자를 생성할 수 없음: \(filenameString)")
                return
            }
            guard let font = CGFont(fontDataProvider) else {
                print("⚠️ CGFont를 생성할 수 없음: \(filenameString)")
                return
            }
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterGraphicsFont(font, &error) {
                if let errorRef = error?.takeRetainedValue() {
                    let errorDescription = CFErrorCopyDescription(errorRef)
                    print("⚠️ 폰트 등록 실패: \(filenameString), 오류: \(errorDescription ?? "알 수 없는 오류" as CFString)")
                } else {
                    print("⚠️ 폰트 등록 실패: \(filenameString)")
                }
            } else {
                print("✅ 폰트 등록 성공: \(filenameString)")
            }
        } catch {
            print("⚠️ 폰트 데이터 로드 실패: \(filenameString), 오류: \(error.localizedDescription)")
        }
    }
}
