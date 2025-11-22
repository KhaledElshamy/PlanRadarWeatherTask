//
//  SearchView.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import SwiftUI
import Combine

/// View for searching and adding cities.
///
/// **Specification Interpretation:**
/// This view provides a search interface for finding cities via the weather API
/// and adding them to local storage. It displays search results, loading states,
/// and error messages.
///
/// **Access Control:**
/// - Internal struct: Used within the module
/// - Public View conformance: SwiftUI requirement
struct SearchView: View {

    @ObservedObject var viewModel: SearchViewModel
    let onCancel: () -> Void
    
    @State private var query: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var latestResult: SearchResult?

    var body: some View {
        ZStack {
            Colors.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                header
                description
                searchField
                
                if let result = latestResult {
                    Text("Saved \(result.city.displayName)")
                        .foregroundColor(.pink)
                        .font(.callout)
                        .padding(.horizontal)
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()

            if isLoading {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
            }
        }
        .onReceive(viewModel.query) { query in
            self.query = query
        }
        .onReceive(viewModel.isLoading) { loading in
            self.isLoading = loading
        }
        .onReceive(viewModel.errorMessage) { message in
            self.errorMessage = message
        }
        .onReceive(viewModel.latestResult) { result in
            self.latestResult = result
        }
    }

    /// Header section with title and cancel button.
    private var header: some View {
        HStack {
            Text("Add City")
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)

            Spacer()

            Button("Cancel") {
                onCancel()
            }
            .foregroundColor(.pink)
        }
    }

    /// Description text for the search field.
    private var description: some View {
        Text("Enter city, postcode or airport location")
            .foregroundColor(.white.opacity(0.8))
            .font(.callout)
    }

    /// Search field with text input and search button.
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.6))
            
            TextField("Search", text: $query)
                .foregroundColor(.white)
                .onSubmit {
                    viewModel.submitSubject.send()
                }
                .onChange(of: query) { newValue in
                    viewModel.querySubject.send(newValue)
                }
            
            Button("Search") {
                viewModel.submitSubject.send()
            }
            .foregroundColor(.pink)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(14)
    }

    /// Color definitions for the search view.
    private enum Colors {
        static let background = LinearGradient(
            gradient: Gradient(colors: [Color.black, Color(red: 0.06, green: 0.06, blue: 0.09)]),
            startPoint: .top,
            endPoint: .bottom
        )
    }
}
