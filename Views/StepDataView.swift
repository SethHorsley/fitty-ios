// File: ./Views/StepDataView.swift

import SwiftUI

struct StepDataView: View {
    @StateObject private var viewModel = StepDataViewModel()
    @State private var selectedTimePeriod: TimePeriod = .today

    var body: some View {
        List {
            Section(header: Text("Time Period")) {
                Picker("Select Time Period", selection: $selectedTimePeriod) {
                    ForEach(TimePeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: selectedTimePeriod) { _, newValue in
                    viewModel.fetchStepData(for: newValue)
                }
            }

            Section(header: Text("Step Data")) {
                ForEach(Array(viewModel.stepData.enumerated()), id: \.element.id) { index, data in
                    StepDataRow(data: data)
                }
            }
        }
        .navigationTitle("Step Details")
        .onAppear {
            viewModel.fetchStepData(for: selectedTimePeriod)
        }
    }
}

struct StepDataRow: View {
    let data: StepData
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Count:")
                Spacer()
                Text("\(data.count) steps")
                    .bold()
            }
            
            HStack {
                Text("Start:")
                Spacer()
                Text(dateFormatter.string(from: data.startDate))
            }
            
            HStack {
                Text("End:")
                Spacer()
                Text(dateFormatter.string(from: data.endDate))
            }
            
            HStack {
                Text("Source:")
                Spacer()
                Text(data.source)
            }
            
            if let device = data.device {
                HStack {
                    Text("Device:")
                    Spacer()
                    Text(device)
                }
            }
            
            if let metadata = data.metadata, !metadata.isEmpty {
                Text("Metadata:")
                    .font(.headline)
                ForEach(Array(metadata.keys), id: \.self) { key in
                    HStack {
                        Text(key)
                        Spacer()
                        Text("\(String(describing: metadata[key]!))")
                    }
                    .font(.caption)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

