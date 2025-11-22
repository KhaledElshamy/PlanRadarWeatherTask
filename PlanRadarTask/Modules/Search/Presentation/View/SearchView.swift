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
    
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var query: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var latestResult: SearchResult?
    
    private var colors: AppColors {
        AppColors(colorScheme: colorScheme)
    }

    var body: some View {
        ZStack {
            colors.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                header
                description
                searchField
                
                if let result = latestResult {
                    Text("Saved \(result.city.displayName)")
                        .foregroundColor(colors.buttonAccent)
                        .font(.callout)
                        .padding(.horizontal)
                }
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(AppColors.error)
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
                .foregroundColor(colors.primaryText)

            Spacer()

            Button("Cancel") {
                onCancel()
            }
            .foregroundColor(colors.buttonAccent)
        }
    }

    /// Description text for the search field.
    private var description: some View {
        Text("Enter city, postcode or airport location")
            .foregroundColor(colors.secondaryText)
            .font(.callout)
    }

    /// Search field with text input and search button.
    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(colors.icon)
            
            TextField("Search", text: $query)
                .foregroundColor(colors.primaryText)
                .onSubmit {
                    viewModel.submitSubject.send()
                }
                .onChange(of: query) { newValue in
                    viewModel.querySubject.send(newValue)
                }
            
            Button("Search") {
                viewModel.submitSubject.send()
            }
            .foregroundColor(colors.buttonAccent)
        }
        .padding()
        .background(colors.cardBackground.opacity(0.5))
        .cornerRadius(14)
    }
}
