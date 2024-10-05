import Foundation
import HealthKit

struct StepData: Identifiable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    let count: Int
    let source: String
    let device: String?
    let metadata: [String: Any]?
}

class StepDataViewModel: ObservableObject {
    @Published var stepData: [StepData] = []
    private let healthStore = HKHealthStore()
    
    func fetchStepData(for timePeriod: TimePeriod) {
        guard let stepsQuantityType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }
        
        let now = Date()
        let startDate = calculateStartDate(for: timePeriod)
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: stepsQuantityType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { [weak self] (query, samples, error) in
            guard let samples = samples as? [HKQuantitySample], error == nil else {
                print("Error fetching step data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            let stepData = samples.map { sample in
                StepData(startDate: sample.startDate,
                         endDate: sample.endDate,
                         count: Int(sample.quantity.doubleValue(for: .count())),
                         source: sample.sourceRevision.source.name,
                         device: sample.device?.name,
                         metadata: sample.metadata)
            }
            
            DispatchQueue.main.async {
                self?.stepData = stepData
            }
        }
        
        healthStore.execute(query)
    }

    private func calculateStartDate(for timePeriod: TimePeriod) -> Date {
        let now = Date()
        switch timePeriod {
        case .today:
            return Calendar.current.startOfDay(for: now)
        case .yesterday:
            return Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: now))!
        case .last3Days:
            return Calendar.current.date(byAdding: .day, value: -2, to: Calendar.current.startOfDay(for: now))!
        case .last7Days:
            return Calendar.current.date(byAdding: .day, value: -6, to: Calendar.current.startOfDay(for: now))!
        case .lastMonth:
            return Calendar.current.date(byAdding: .month, value: -1, to: Calendar.current.startOfDay(for: now))!
        case .allTime:
            return Date.distantPast
        }
    }
}

