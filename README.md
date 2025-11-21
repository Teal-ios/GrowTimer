# GrowTimer

Grow Timer - 나를 발전시키는 소중한 시간

Grow Timer는 스마트폰 중독을 방지하기 위한 앱입니다. 핸드폰의 유혹 속에 빠져 나오지 못하는 이들에게, 핸드폰을 내려놓고 자신의 개발에 온전히 집중할 수 있도록 합니다.

<img width="945" height="357" alt="제목 없는 디자인 (5)" src="https://github.com/user-attachments/assets/1b1d478e-17bd-41b6-9407-587042a80b80" />



### 개발 기간
2025.04.28 ~ 2025.05.09 (12일)

### 기술 스택
- **CI/CD** : **XCodeCloud**를 활용한 CI/CD 구축 (Domain 독립적 테스트 구성 및 테스트 통과 이후 자동배포 설계)
- **Tuist Module** : **Tuist**를 활용하여 앱 전체를 Domain, Data, Present 모듈 기반으로 구성.
- **ReactorKit** : **ReactorKit**을 활용하여 단방향 데이터 Flow 기반으로 전체 프로젝트 구성.
- **Custom Module** : Toast를 Custom으로 Module로 구성.
- **DIContainer** : DIContainer를 통해 AppDelegate에서 Register를 활용하여 전체 UseCase 주입.
- **DataBase** : CoreData를 활용한 DB 관리 및 Storage / Repository / UseCase를 통한 외부 데이터 작업 분리

![graph](https://github.com/user-attachments/assets/e5822ceb-64dd-44ca-a230-c96e128ce9ab)

### 회고
- App 모듈이 DIContainer 주입을 통한 작업으로 인해 Domain, Data, Utility 모듈에 의존하고 있는 지점
- 추후 Interface 모듈을 추가로 두어 App Module에서 직접적으로 의존하지 않도록 개선 예정
