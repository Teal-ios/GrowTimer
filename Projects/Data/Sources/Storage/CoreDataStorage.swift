//
//  CoreDataStorage.swift
//  Data
//
//  Created by Den on 5/4/25.
//  Copyright © 2025 Den. All rights reserved.
//

import Foundation
import CoreData
import Domain

public final class CoreDataStorage {
   // 각 모델별 저장소 인스턴스를 관리하는 딕셔너리
   private static var storages: [String: CoreDataStorage] = [:]
   
   // 모델별 팩토리 메서드
   public static func storage(for modelName: String) -> CoreDataStorage {
       if let storage = storages[modelName] {
           return storage
       }
       
       let newStorage = CoreDataStorage(modelName: modelName)
       storages[modelName] = newStorage
       return newStorage
   }
   
   // 편의를 위한 타입별 접근 메서드
   public static var coinStorage: CoreDataStorage {
       return storage(for: "CoinDTO")
   }
   
   public static var fontStorage: CoreDataStorage {
       return storage(for: "FontDTO")
   }
   
   public static var themaStorage: CoreDataStorage {
       return storage(for: "ThemaDTO")
   }
   
   public static var userStorage: CoreDataStorage {
       return storage(for: "UserDTO")
   }
   
   private let modelName: String
   private let container: NSPersistentContainer
   
   private init(modelName: String) {
       self.modelName = modelName
       
       // 여러 번들에서 모델 파일 찾기 시도
       var container: NSPersistentContainer?
       let bundles = [Bundle.module, Bundle.main]
       
       for bundle in bundles {
           if let modelURL = bundle.url(forResource: modelName, withExtension: "momd") {
               print("모델 파일 발견: \(modelURL)")
               if let model = NSManagedObjectModel(contentsOf: modelURL) {
                   container = NSPersistentContainer(name: modelName, managedObjectModel: model)
                   break
               }
           }
       }
       
       // 모델을 찾지 못한 경우 기본 컨테이너 생성
       if container == nil {
           print("모델 파일을 찾을 수 없습니다. 기본 컨테이너 사용: \(modelName)")
           container = NSPersistentContainer(name: modelName)
       }
       
       self.container = container!
       setupDatabase()
   }
   
   // MARK: - 셋업
   private func setupDatabase() {
       container.loadPersistentStores { [weak self] storeDescription, error in
           if let error = error {
               print("CoreData 로딩 에러: \(error.localizedDescription)")
               return
           }
           
           print("\(self?.modelName ?? "") 모델 로드 성공")
           
           // 엔티티 정보 출력 (디버깅용)
           if let entities = self?.container.managedObjectModel.entities {
               print("사용 가능한 엔티티:")
               for entity in entities {
                   print("- \(entity.name ?? "unnamed") (클래스: \(entity.managedObjectClassName))")
               }
           }
           
           // 병합 정책 설정 (동시성 처리를 위해)
           self?.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
           self?.container.viewContext.automaticallyMergesChangesFromParent = true
           
           // 성능 최적화
           self?.container.viewContext.shouldDeleteInaccessibleFaults = true
       }
   }
   
   // MARK: - 컨텍스트 접근 메서드
   var mainContext: NSManagedObjectContext {
       return container.viewContext
   }
   
   // 백그라운드 컨텍스트 생성
   func backgroundContext() -> NSManagedObjectContext {
       return container.newBackgroundContext()
   }
   
   // MARK: - CRUD 기본 연산
   
   // 생성 (Create)
   public func create<T: NSManagedObject>(_ object: T.Type) -> T {
       let entity = T(context: mainContext)
       return entity
   }
   
   // 조회 (Read)
   public func fetch<T: NSManagedObject>(_ objectType: T.Type, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil, limit: Int? = nil) -> [T] {
       let request = NSFetchRequest<T>(entityName: String(describing: objectType))
       request.predicate = predicate
       request.sortDescriptors = sortDescriptors
       
       if let limit = limit {
           request.fetchLimit = limit
       }
       
       do {
           return try mainContext.fetch(request)
       } catch {
           print("CoreData 조회 에러: \(error.localizedDescription)")
           return []
       }
   }
   
   // 단일 객체 조회
   func fetchOne<T: NSManagedObject>(_ objectType: T.Type, predicate: NSPredicate) -> T? {
       let results = fetch(objectType, predicate: predicate, limit: 1)
       return results.first
   }
   
   // ID로 객체 조회
   func fetchById<T: NSManagedObject>(_ objectType: T.Type, id: UUID, idName: String = "id") -> T? {
       let predicate = NSPredicate(format: "%K == %@", idName, id as CVarArg)
       return fetchOne(objectType, predicate: predicate)
   }
   
   // 갱신 (Update)
   func save() {
       if mainContext.hasChanges {
           do {
               try mainContext.save()
           } catch {
               print("CoreData 저장 에러: \(error.localizedDescription)")
           }
       }
   }
   
   // 삭제 (Delete)
   func delete<T: NSManagedObject>(_ object: T) {
       mainContext.delete(object)
       save()
   }
   
   // 여러 객체 삭제
   func deleteMultiple<T: NSManagedObject>(_ objects: [T]) {
       for object in objects {
           mainContext.delete(object)
       }
       save()
   }
   
   // 조건에 맞는 객체 모두 삭제
   func deleteAll<T: NSManagedObject>(_ objectType: T.Type, predicate: NSPredicate? = nil) {
       let request = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: objectType))
       request.predicate = predicate
       
       let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: request)
       batchDeleteRequest.resultType = .resultTypeObjectIDs
       
       do {
           let result = try mainContext.execute(batchDeleteRequest) as? NSBatchDeleteResult
           if let objectIDs = result?.result as? [NSManagedObjectID] {
               let changes = [NSDeletedObjectsKey: objectIDs]
               NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [mainContext])
           }
       } catch {
           print("CoreData 일괄 삭제 에러: \(error.localizedDescription)")
       }
   }
   
   // MARK: - 백그라운드 작업
   // 백그라운드에서 저장 작업 수행 메서드
   func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
       container.performBackgroundTask { context in
           block(context)
           
           if context.hasChanges {
               do {
                   try context.save()
               } catch {
                   print("CoreData 백그라운드 저장 에러: \(error.localizedDescription)")
               }
           }
       }
   }
   
   // 모델 개수 조회
   func count<T: NSManagedObject>(_ objectType: T.Type, predicate: NSPredicate? = nil) -> Int {
       let request = NSFetchRequest<T>(entityName: String(describing: objectType))
       request.predicate = predicate
       
       do {
           return try mainContext.count(for: request)
       } catch {
           print("CoreData 개수 조회 에러: \(error.localizedDescription)")
           return 0
       }
   }
}
