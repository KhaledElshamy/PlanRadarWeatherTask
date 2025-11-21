//
//  PlanRadarTaskApp.swift
//  PlanRadarTask
//
//  Created by Khaled Elshamy on 21/11/2025.
//

import SwiftUI

@main
struct PlanRadarTaskApp: App {
    @StateObject private var coordinator = AppFlowCoordinator()

    var body: some Scene {
        WindowGroup {
            coordinator.rootView
        }
    }
}
