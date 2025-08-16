import Foundation

class DependencyContainer {
    static let shared = DependencyContainer()
    
    private init() {}
    
    // Services
    lazy var locationService: LocationManager = {
        return LocationManager()
    }()
    
    lazy var arSessionService: ARSessionManager = {
        return ARSessionManager()
    }()
    
    lazy var treasureService: TreasureService = {
        return TreasureService()
    }()
    
    lazy var userService: UserService = {
        return UserService()
    }()
    
    // ViewModels
    func makeMapViewModel() -> MapViewModel {
        return MapViewModel(
            locationManager: locationService,
            treasureService: treasureService
        )
    }
    
    // TODO: Implement ARCameraViewModel
    // func makeARCameraViewModel() -> ARCameraViewModel {
    //     return ARCameraViewModel(
    //         arSessionManager: arSessionService,
    //         locationManager: locationService,
    //         treasureService: treasureService
    //     )
    // }
    
    // TODO: Implement ProfileViewModel
    // func makeProfileViewModel() -> ProfileViewModel {
    //     return ProfileViewModel(userService: userService)
    // }
}