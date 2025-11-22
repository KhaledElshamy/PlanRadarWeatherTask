//
//  CityHistoryView.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import SwiftUI
import Combine

/// View displaying historical weather data for a city.
///
/// **Specification Interpretation:**
/// This view presents a list of historical weather entries for a specific city,
/// showing the date/time when data was requested and the weather conditions.
/// It matches the design specification with a dark theme and red accent colors.
///
/// **Access Control:**
/// - Internal struct: Used within the module
/// - Public View conformance: SwiftUI requirement
struct CityHistoryView: View {
    
    @ObservedObject var viewModel: CityHistoryViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var historyEntries: [CityHistoryEntry] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var cityName: String = ""
    @State private var selectedEntry: CityHistoryEntry?
    
    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                header
                content
            }
        }
        .navigationBarHidden(true)
        .onReceive(viewModel.historyEntries) { entries in
            self.historyEntries = entries
        }
        .onReceive(viewModel.isLoading) { loading in
            self.isLoading = loading
        }
        .onReceive(viewModel.errorMessage) { message in
            self.errorMessage = message
        }
        .onReceive(viewModel.cityName) { name in
            self.cityName = name
        }
        .sheet(item: $selectedEntry) { entry in
            CityHistoryDetailView(entry: entry)
        }
    }
    
    // MARK: - Header
    
    /// Header section with back button and city name title.
    private var header: some View {
        HStack(spacing: 16) {
            Button(action: { dismiss() }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Colors.accent)
                        .frame(width: 50, height: 40)
                    Image(systemName: "arrow.left")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            
            Spacer()
            
            VStack(spacing: 0) {
                Text(cityName.uppercased())
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                Text("HISTORICAL")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Invisible spacer to center the title
            Color.clear
                .frame(width: 50, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Content
    
    /// Main content area with history list.
    private var content: some View {
        Group {
            if historyEntries.isEmpty, !isLoading {
                emptyState
            } else {
                historyList
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    /// Empty state view when no history is available.
    private var emptyState: some View {
        VStack(spacing: 16) {
            Text("No historical data available")
                .foregroundColor(.gray)
                .font(.callout)
            Text("Search for this city to start building history")
                .foregroundColor(.gray.opacity(0.7))
                .font(.caption)
        }
        .padding()
    }
    
    /// List of historical weather entries.
    private var historyList: some View {
        List {
            ForEach(historyEntries) { entry in
                Button(action: {
                    selectedEntry = entry
                }) {
                    HistoryRow(entry: entry)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: - Colors
    
    private enum Colors {
        static let background = LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.03, green: 0.03, blue: 0.05),
                Color(red: 0.01, green: 0.01, blue: 0.03)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        static let accent = Color(red: 1, green: 0.27, blue: 0.41)
    }
}

// MARK: - History Row

/// Individual history entry row component.
///
/// **Access Control:**
/// - Private struct: Used only within CityHistoryView
private struct HistoryRow: View {
    let entry: CityHistoryEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Date and time in gray
            Text(formatDate(entry.requestDate))
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.gray)
            
            // Weather condition and temperature in red
            Text("\(entry.description), \(entry.temperature)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 1, green: 0.27, blue: 0.41))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    /// Formats the date for display.
    ///
    /// **Specification:** Formats the date as "DD.MM.YYYY - HH:mm" matching the design.
    ///
    /// - Parameter date: The date to format
    /// - Returns: Formatted date string
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy - HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - History Detail View

/// View displaying detailed information for a historical entry.
///
/// **Access Control:**
/// - Private struct: Used only within CityHistoryView
private struct CityHistoryDetailView: View {
    let entry: CityHistoryEntry
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.03, green: 0.03, blue: 0.05),
                        Color(red: 0.01, green: 0.01, blue: 0.03)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Weather Icon
                    if let iconURL = entry.iconURL {
                        AsyncImage(url: iconURL) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 120, height: 120)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 120, height: 120)
                            case .failure:
                                Image(systemName: "cloud.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(Color(red: 1, green: 0.27, blue: 0.41))
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                    
                    // Weather Details
                    VStack(spacing: 20) {
                        DetailRow(label: "DESCRIPTION", value: entry.description)
                        DetailRow(label: "TEMPERATURE", value: entry.temperature)
                        DetailRow(label: "HUMIDITY", value: entry.humidity)
                        DetailRow(label: "WINDSPEED", value: entry.wind)
                        DetailRow(label: "REQUESTED", value: formatDate(entry.requestDate))
                        DetailRow(label: "WEATHER DATE", value: formatDate(entry.weatherDate))
                    }
                }
                .padding(32)
            }
            .navigationTitle(entry.cityName.uppercased())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Color(red: 1, green: 0.27, blue: 0.41))
                }
            }
        }
    }
    
    /// Formats the date for display.
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy - HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Detail Row

/// Individual detail row component.
private struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(red: 1, green: 0.27, blue: 0.41))
        }
    }
}

