import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var viewModel = LeaderboardViewModel()
    @Environment(\.modelContext) private var modelContext
    @Query private var items: [Item]

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Time Period")) {
                    Picker("Select Time Period", selection: $viewModel.selectedTimePeriod) {
                        ForEach(TimePeriod.allCases) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: viewModel.selectedTimePeriod) { _, newValue in
                        viewModel.fetchSteps(for: newValue)
                    }
                }

                Section(header: Text("Your Steps")) {
                    HStack {
                        Text("Automatic Steps")
                        Spacer()
                        Text("\(viewModel.userAutomaticSteps)")
                    }
                    HStack {
                        Text("Manual Steps")
                        Spacer()
                        Text("\(viewModel.userManualSteps)")
                    }
                    HStack {
                        Text("Total Steps")
                        Spacer()
                        Text("\(viewModel.userTotalSteps)")
                    }
                }

                Section(header: Text("Leaderboard")) {
                    ForEach(viewModel.friends.sorted { $0.automaticSteps > $1.automaticSteps }) { friend in
                        HStack {
                            Text(friend.name)
                            Spacer()
                            Text("\(friend.automaticSteps)")
                        }
                    }
                }

                Section(header: Text("Health Data")) {
                    NavigationLink(destination: StepDataView()) {
                        Text("View Detailed Step Data")
                    }
                }

                Section(header: Text("Items")) {
                    ForEach(items) { item in
                        NavigationLink {
                            Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                        } label: {
                            Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                        }
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            .navigationTitle("Fitty")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        }
        .onAppear {
            viewModel.requestAuthorization()
            viewModel.fetchLeaderboard()
            viewModel.fetchSteps(for: .today) // Fetch steps for today initially
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
