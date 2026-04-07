import Foundation

typealias SagaNext = (SagaRequest, SagaContext) async -> SagaResponse

protocol SagaStep {
    var name: String { get }
    
    func execute(
        request: SagaRequest,
        context: SagaContext,
        next: @escaping SagaNext
    ) async -> SagaResponse
    
    func compensate(context: SagaContext) async
}

// MARK: - Saga Orchestrator

final class SagaOrchestrator {
    private var steps: [SagaStep] = []
    private let finalHandler: (SagaRequest, SagaContext) async -> SagaResponse
    
    init(finalHandler: @escaping (SagaRequest, SagaContext) async -> SagaResponse) {
        self.finalHandler = finalHandler
    }
    
    func use(_ step: SagaStep) {
        steps.append(step)
    }
    
    func execute(request: SagaRequest, context: SagaContext) async -> SagaResponse {
        let response = await executeChain(at: 0, request: request, context: context)
        
        // If error occurred, rollback executed steps
        if case .error = response {
            await rollback(context: context)
        }
        
        return response
    }
    
    private func executeChain(
        at index: Int,
        request: SagaRequest,
        context: SagaContext
    ) async -> SagaResponse {
        if index >= steps.count {
            return await finalHandler(request, context)
        }
        
        let step = steps[index]
        
        let next: SagaNext = { [weak self] req, ctx in
            guard let self = self else {
                return .error(SagaError.invalidData)
            }
            return await self.executeChain(at: index + 1, request: req, context: ctx)
        }
        
        let response = await step.execute(request: request, context: context, next: next)
        
        // Track successful steps for potential rollback
        if case .error = response {
            // Don't add to executed steps if failed
        } else {
            if !context.executedSteps.contains(step.name) {
                context.executedSteps.append(step.name)
            }
        }
        
        return response
    }
    
    private func rollback(context: SagaContext) async {
        for stepName in context.executedSteps.reversed() {
            if let step = steps.first(where: { $0.name == stepName }) {
                await step.compensate(context: context)
            }
        }
        
        context.executedSteps.removeAll()
    }
}
