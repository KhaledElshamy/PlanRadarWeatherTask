//
//  AppColors.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import SwiftUI

/// Centralized color system that adapts to light and dark mode.
///
/// **Specification Interpretation:**
/// This struct provides a unified color system for the entire application,
/// automatically adapting to the user's appearance preference (light/dark mode).
/// Colors are defined to match the design specifications for both modes.
///
/// **Access Control:**
/// - Internal struct: Used across the application
struct AppColors {
    
    /// The current color scheme (light or dark mode).
    let colorScheme: ColorScheme
    
    /// Initializes AppColors with the current color scheme.
    ///
    /// - Parameter colorScheme: The current color scheme from environment
    init(colorScheme: ColorScheme) {
        self.colorScheme = colorScheme
    }
    
    // MARK: - Background Colors
    
    /// Main background gradient that adapts to appearance mode.
    ///
    /// **Light Mode:** Light grey/white gradient
    /// **Dark Mode:** Dark gradient (existing dark theme)
    var background: LinearGradient {
        switch colorScheme {
        case .light:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.96, green: 0.96, blue: 0.97),
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        case .dark:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.03, green: 0.03, blue: 0.05),
                    Color(red: 0.01, green: 0.01, blue: 0.03)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        @unknown default:
            return LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.96, green: 0.96, blue: 0.97),
                    Color.white
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    /// Card background color that adapts to appearance mode.
    ///
    /// **Light Mode:** White or very light grey
    /// **Dark Mode:** Dark grey (existing)
    var cardBackground: Color {
        switch colorScheme {
        case .light:
            return Color.white
        case .dark:
            return Color(red: 0.15, green: 0.15, blue: 0.17)
        @unknown default:
            return Color.white
        }
    }
    
    // MARK: - Text Colors
    
    /// Primary text color that adapts to appearance mode.
    ///
    /// **Light Mode:** Dark grey (matching image)
    /// **Dark Mode:** White
    var primaryText: Color {
        switch colorScheme {
        case .light:
            return Color(red: 0.2, green: 0.2, blue: 0.25)
        case .dark:
            return Color.white
        @unknown default:
            return Color(red: 0.2, green: 0.2, blue: 0.25)
        }
    }
    
    /// Secondary text color that adapts to appearance mode.
    ///
    /// **Light Mode:** Medium grey
    /// **Dark Mode:** Light grey
    var secondaryText: Color {
        switch colorScheme {
        case .light:
            return Color(red: 0.4, green: 0.4, blue: 0.45)
        case .dark:
            return Color.gray
        @unknown default:
            return Color(red: 0.4, green: 0.4, blue: 0.45)
        }
    }
    
    /// Header text color that adapts to appearance mode.
    ///
    /// **Light Mode:** Dark grey
    /// **Dark Mode:** Grey
    var headerText: Color {
        switch colorScheme {
        case .light:
            return Color(red: 0.3, green: 0.3, blue: 0.35)
        case .dark:
            return Color.gray
        @unknown default:
            return Color(red: 0.3, green: 0.3, blue: 0.35)
        }
    }
    
    // MARK: - Accent Colors
    
    /// Primary accent color (pink/red) - same in both modes.
    static var accent: Color {
        Color(red: 1, green: 0.27, blue: 0.41)
    }
    
    /// Button accent color that adapts to appearance mode.
    ///
    /// **Light Mode:** Blue (matching image)
    /// **Dark Mode:** Pink/red accent
    var buttonAccent: Color {
        switch colorScheme {
        case .light:
            return Color(red: 0.0, green: 0.48, blue: 1.0) // System blue
        case .dark:
            return Color(red: 1, green: 0.27, blue: 0.41)
        @unknown default:
            return Color(red: 0.0, green: 0.48, blue: 1.0)
        }
    }
    
    // MARK: - Icon Colors
    
    /// Icon color that adapts to appearance mode.
    ///
    /// **Light Mode:** Dark grey (matching image)
    /// **Dark Mode:** Grey
    var icon: Color {
        switch colorScheme {
        case .light:
            return Color(red: 0.3, green: 0.3, blue: 0.35)
        case .dark:
            return Color.gray
        @unknown default:
            return Color(red: 0.3, green: 0.3, blue: 0.35)
        }
    }
    
    /// Arrow/chevron color that adapts to appearance mode.
    ///
    /// **Light Mode:** Dark grey
    /// **Dark Mode:** Accent color
    var arrow: Color {
        switch colorScheme {
        case .light:
            return Color(red: 0.3, green: 0.3, blue: 0.35)
        case .dark:
            return Color(red: 1, green: 0.27, blue: 0.41)
        @unknown default:
            return Color(red: 0.3, green: 0.3, blue: 0.35)
        }
    }
    
    // MARK: - Utility Colors
    
    /// Error/red color - same in both modes.
    static var error: Color {
        Color.red
    }
    
    /// Success color - same in both modes.
    static var success: Color {
        Color.green
    }
}


