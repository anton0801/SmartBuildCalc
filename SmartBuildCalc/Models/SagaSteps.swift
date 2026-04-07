import Foundation
import AppsFlyerLib

// MARK: - Logging Step

final class LoggingStep: SagaStep {
    let name = "LoggingStep"
    
    func execute(
        request: SagaRequest,
        context: SagaContext,
        next: @escaping SagaNext
    ) async -> SagaResponse {
        let response = await next(request, context)
        return response
    }
    
    func compensate(context: SagaContext) async {
    }
}

// MARK: - Lock Step

final class LockStep: SagaStep {
    let name = "LockStep"
    
    func execute(
        request: SagaRequest,
        context: SagaContext,
        next: @escaping SagaNext
    ) async -> SagaResponse {
        if context.isLocked {
            switch request {
            case .finalizeWithEndpoint, .requestPermission, .deferPermission:
                return await next(request, context)
            default:
                return .error(SagaError.invalidData)
            }
        }
        
        return await next(request, context)
    }
    
    func compensate(context: SagaContext) async {
        context.isLocked = false
    }
}

// MARK: - Storage Step

final class StorageStep: SagaStep {
    let name = "StorageStep"
    private let storage: StorageService
    
    init(storage: StorageService) {
        self.storage = storage
    }
    
    func execute(
        request: SagaRequest,
        context: SagaContext,
        next: @escaping SagaNext
    ) async -> SagaResponse {
        switch request {
        case .initialize:
            let stored = storage.loadState()
            context.tracking = stored.tracking
            context.navigation = stored.navigation
            // ❌ НЕ ЗАГРУЖАЕМ endpoint!
            context.mode = stored.mode
            context.isFirstLaunch = stored.isFirstLaunch
            context.permission = SagaContext.PermissionData(
                isGranted: stored.permission.isGranted,
                isDenied: stored.permission.isDenied,
                lastAsked: stored.permission.lastAsked
            )
            return await next(request, context)
            
        case .handleTracking(let data):
            let converted = data.mapValues { "\($0)" }
            context.tracking = converted
            storage.saveTracking(converted)
            return await next(request, context)
            
        case .handleNavigation(let data):
            let converted = data.mapValues { "\($0)" }
            context.navigation = converted
            storage.saveNavigation(converted)
            return await next(request, context)
            
        case .finalizeWithEndpoint(let url):
            context.endpoint = url
            context.mode = "Active"
            context.isFirstLaunch = false
            context.isLocked = true
            storage.saveEndpoint(url)
            storage.saveMode("Active")
            storage.markLaunched()
            return await next(request, context)
            
        case .requestPermission, .deferPermission:
            let response = await next(request, context)
            storage.savePermissions(context.permission)
            return response
            
        default:
            return await next(request, context)
        }
    }
    
    func compensate(context: SagaContext) async {
        // Rollback: clear saved data
        context.tracking.removeAll()
        context.navigation.removeAll()
        context.endpoint = nil
        context.mode = nil
    }
}

// MARK: - Validation Step

final class ValidationStep: SagaStep {
    let name = "ValidationStep"
    private let validator: ValidationService
    
    init(validator: ValidationService) {
        self.validator = validator
    }
    
    func execute(
        request: SagaRequest,
        context: SagaContext,
        next: @escaping SagaNext
    ) async -> SagaResponse {
        guard case .processValidation = request else {
            return await next(request, context)
        }
        
        guard context.hasTracking() else {
            return .validationCompleted(false)
        }
        
        do {
            let isValid = try await validator.validate()
            return .validationCompleted(isValid)
        } catch {
            return .validationCompleted(false)
        }
    }
    
    func compensate(context: SagaContext) async {
    }
}

// MARK: - Network Step

final class NetworkStep: SagaStep {
    let name = "NetworkStep"
    private let network: NetworkService
    
    init(network: NetworkService) {
        self.network = network
    }
    
    func execute(
        request: SagaRequest,
        context: SagaContext,
        next: @escaping SagaNext
    ) async -> SagaResponse {
        switch request {
        case .fetchAttribution(let deviceID):
            do {
                var fetched = try await network.fetchAttribution(deviceID: deviceID)
                
                for (key, value) in context.navigation {
                    if fetched[key] == nil {
                        fetched[key] = value
                    }
                }
                
                return .attributionFetched(fetched)
            } catch {
                return .error(error)
            }
            
        case .fetchEndpoint(let tracking):
            do {
                let endpoint = try await network.fetchEndpoint(tracking: tracking)
                return .endpointFetched(endpoint)
            } catch {
                return .error(error)
            }
            
        default:
            return await next(request, context)
        }
    }
    
    func compensate(context: SagaContext) async {
    }
}

// MARK: - Permission Step

final class PermissionStep: SagaStep {
    let name = "PermissionStep"
    private let notificationService: NotificationService
    
    init(notificationService: NotificationService) {
        self.notificationService = notificationService
    }
    
    func execute(
        request: SagaRequest,
        context: SagaContext,
        next: @escaping SagaNext
    ) async -> SagaResponse {
        switch request {
        case .requestPermission:
            return await withCheckedContinuation { continuation in
                notificationService.requestPermission { granted in
                    if granted {
                        context.permission.isGranted = true
                        context.permission.isDenied = false
                        context.permission.lastAsked = Date()
                        self.notificationService.registerForPush()
                        continuation.resume(returning: .permissionGranted)
                    } else {
                        context.permission.isGranted = false
                        context.permission.isDenied = true
                        context.permission.lastAsked = Date()
                        continuation.resume(returning: .permissionDenied)
                    }
                }
            }
            
        case .deferPermission:
            context.permission.lastAsked = Date()
            return .permissionDeferred
            
        default:
            return await next(request, context)
        }
    }
    
    func compensate(context: SagaContext) async {
    }
}

// MARK: - Business Logic Step

final class BusinessLogicStep: SagaStep {
    let name = "BusinessLogicStep"
    
    func execute(
        request: SagaRequest,
        context: SagaContext,
        next: @escaping SagaNext
    ) async -> SagaResponse {
        switch request {
        case .initialize:
            return .initialized
            
        case .handleTracking:
            return .trackingStored(context.tracking)
            
        case .handleNavigation:
            return .navigationStored(context.navigation)
            
        case .networkStatusChanged(let isConnected):
            return isConnected ? .hideOfflineView : .showOfflineView
            
        case .timeout:
            return .navigateToMain
            
        case .finalizeWithEndpoint:
            if context.permission.canAsk {
                return .showPermissionPrompt
            } else {
                return .navigateToWeb
            }
            
        default:
            return await next(request, context)
        }
    }
    
    func compensate(context: SagaContext) async {
    }
}
