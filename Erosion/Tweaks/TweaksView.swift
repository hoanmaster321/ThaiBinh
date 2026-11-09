//
//  TweaksView.swift
//  Erosion
//
//  Created by lunginspector on 8/26/26.
//

import SwiftUI


struct TweaksView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(destination: PosterBoardView()) {
                        Label("Custom Wallpapers (PosterBoard)", systemImage: "photo.on.rectangle.angled")
                    }
                    NavigationLink(destination: KeypadView()) {
                        Label("Dialer Keypad Themer", systemImage: "circle.grid.3x3.fill")
                    }
                    NavigationLink(destination: SpringBoardTweaksView()) {
                        Label("SpringBoard, PosterBoard & SystemGroup", systemImage: "sparkles.rectangle.stack")
                    }
                } header: {
                    HeaderLabel("Theming & UI", symbol: "paintbrush")
                }
                
                Section {
                    if raveSupported() || weOnADebugBuild {
                        NavigationLink(destination: GestaltView()) {
                            Label("MobileGestalt Hardware Flags", systemImage: "cpu")
                        }
                        NavigationLink(destination: ConfigView()) {
                            Label("Lock Screen Footnote & Supervision", systemImage: "lock.rectangle.on.rectangle")
                        }
                    }
                    NavigationLink(destination: OperationsView()) {
                        Label("Custom File Overwrite & Presets", systemImage: "wrench.and.screwdriver")
                    }
                } header: {
                    HeaderLabel("System & Eligibility", symbol: "gear")
                }
            }
            .navigationTitle("Tweaks")
        }
    }
}
