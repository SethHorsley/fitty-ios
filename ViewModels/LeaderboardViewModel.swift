import SwiftUI
import HealthKit

enum TimePeriod: String, CaseIterable, Identifiable {
    case today = "Today"
    case yesterday = "Yesterday"
    case last3Days = "Last 3 Days"
    case last7Days = "Last 7 Days"
    case lastMonth = "Last Month"
    case allTime = "All Time"
    
    var id: String { self.rawValue }
}

struct Friend: Identifiable, Codable {
    let id: String
    let name: String
    var automaticSteps: Int
    var manualSteps: Int
    
    var totalSteps: Int {
        automaticSteps + manualSteps
    }
}

class LeaderboardViewModel: ObservableObject {
    @Published var friends: [Friend] = []
    @Published var userAutomaticSteps: Int = 0
    @Published var userManualSteps: Int = 0
    @Published var selectedTimePeriod: TimePeriod = .today
    
    var userTotalSteps: Int {
        userAutomaticSteps + userManualSteps
    }
    
    private let healthStore = HKHealthStore()

    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device.")
            return
        }
        
        let stepsCount = HKObjectType.quantityType(forIdentifier: .stepCount)!
        
        healthStore.requestAuthorization(toShare: [], read: [stepsCount]) { [weak self] success, error in
            if success {
                print("HealthKit authorization successful")
                self?.startObservingSteps()
            } else if let error = error {
                print("HealthKit authorization failed: \(error.localizedDescription)")
            }
        }
    }
    
    func startObservingSteps() {
        guard let stepsQuantityType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            print("Steps quantity type is not available")
            return
        }
        
        let query = HKObserverQuery(sampleType: stepsQuantityType, predicate: nil) { [weak self] _, _, error in
            if let error = error {
                print("Error observing steps: \(error.localizedDescription)")
                return
            }
            print("Steps data changed, fetching latest...")
            self?.fetchSteps(for: .today)
        }
        
        healthStore.execute(query)
        
        // Fetch steps immediately
        fetchSteps(for: .today)
    }
    
    func fetchSteps(for timePeriod: TimePeriod) {
        guard let stepsQuantityType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }
        
        let now = Date()
        let startDate = calculateStartDate(for: timePeriod)
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictStartDate)
        
        let query = HKStatisticsCollectionQuery(quantityType: stepsQuantityType,
                                                quantitySamplePredicate: predicate,
                                                options: [.cumulativeSum, .separateBySource],
                                                anchorDate: startDate,
                                                intervalComponents: DateComponents(day: 1))
        
        query.initialResultsHandler = { [weak self] query, results, error in
            self?.processStepResults(results, error: error)
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

    private func processStepResults(_ results: HKStatisticsCollection?, error: Error?) {
        guard let results = results else {
            print("Failed to fetch steps: \(error?.localizedDescription ?? "Unknown error")")
            return
        }
        
        let now = Date()
        let startDate = calculateStartDate(for: selectedTimePeriod)
        
        var automaticSteps = 0
        var manualSteps = 0
        
        results.enumerateStatistics(from: startDate, to: now) { statistics, _ in
            if let quantity = statistics.sumQuantity() {
                let steps = Int(quantity.doubleValue(for: HKUnit.count()))
                
                // We need to query for the actual samples to check the metadata
                let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount)!
                let predicate = HKQuery.predicateForSamples(withStart: statistics.startDate, end: statistics.endDate, options: .strictStartDate)
                
                let query = HKSampleQuery(sampleType: stepsType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                    guard let samples = samples as? [HKQuantitySample], error == nil else {
                        print("Error querying for samples: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    
                    var localManualSteps = 0
                    var localAutomaticSteps = 0
                    
                    for sample in samples {
                        if let wasUserEntered = sample.metadata?[HKMetadataKeyWasUserEntered] as? Bool, wasUserEntered {
                            localManualSteps += Int(sample.quantity.doubleValue(for: .count()))
                        } else {
                            localAutomaticSteps += Int(sample.quantity.doubleValue(for: .count()))
                        }
                    }
                    
                    DispatchQueue.main.async {
                        manualSteps += localManualSteps
                        automaticSteps += localAutomaticSteps
                        self.userManualSteps = manualSteps
                        self.userAutomaticSteps = automaticSteps
                        print("Updated steps - Automatic: \(self.userAutomaticSteps), Manual: \(self.userManualSteps)")
                        self.objectWillChange.send()
                    }
                }
                
                self.healthStore.execute(query)
            }
        }
    }
    
    func fetchLeaderboard() {
        // Simulated API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.friends = [
                Friend(id: "1", name: "Alice", automaticSteps: 7500, manualSteps: 500),
                Friend(id: "2", name: "Bob", automaticSteps: 9000, manualSteps: 1000),
                Friend(id: "3", name: "Charlie", automaticSteps: 7300, manualSteps: 200)
            ]
        }
    }
}
