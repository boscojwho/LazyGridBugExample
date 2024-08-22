//
//  ContentView.swift
//  LazyGrid
//
//  Created by Bosco Ho on 2024-08-22.
//

import SwiftUI

enum ContentType: CaseIterable, Identifiable, CustomStringConvertible {
    case alphabet, numbers
    
    var id: Self { self }
    var description: String {
        switch self {
        case .alphabet:
            "Alphabet"
        case .numbers:
            "Numbers"
        }
    }
}

struct ContentView: View {
//    let alphabet = Array("abcdefghijklmnopqrstuvwxyz")
//    let numbers = Array("123456789")
    /// Bug persists even when backing data is processed on init.
    let alphabet = Array(Array("abcdefghijklmnopqrstuvwxyz").enumerated())
    let numbers = Array(Array("123456789").enumerated())
    
    @State private var selectedContent: ContentType = .alphabet
    @State private var showAlert = false
    @State private var showAlertWithPresenting = false
    @State private var showAlertWithState = false
    @State private var alertItem: (Int, String)?
    
    var body: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 240))],
                alignment: .center,
                spacing: 12,
                pinnedViews: []
            ) {
                Group {
                    ForEach(items, id: \.element.hashValue) { offset, item in
                        GroupBox {
                            VStack {
                                LabeledContent(String(item), value: "\(offset)")
                                    .fontWeight(.medium)
                                Text("\(item.hashValue)")
                                Button("Alert") {
                                    showAlert = true
                                }
                                /// Bug: Captured data value is incorrect, and changes on each invocation.
                                .alert("Alert: \(String(item)), \(offset)", isPresented: $showAlert) {
                                    Button("Dismiss") {
                                        print("dismissed item \(String(item)) at offset \(offset)")
                                    }
                                }
                                Button("Alert -> P?") {
                                    showAlertWithPresenting = true
                                }
                                /// Bug: Captured data value is incorrect, and changes on each invocation.
                                .alert("Alert: \(String(item)), \(offset)", isPresented: $showAlertWithPresenting, presenting: (offset, item)) { value in
                                    Button("Dismiss") {
                                        print("dismissed presenting item \(String(item)) at offset \(offset)")
                                    }
                                }
                                /// This method works when the `.alert` modifier is moved outside of LazyVGrid's content builder.
                                Button("Alert -> State") {
                                    showAlertWithState = true
                                    alertItem = (offset, String(item))
                                }
                            }
                        }
                        .transition(
                            .asymmetric(
                                insertion: .push(from: .top).combined(with: .opacity),
                                removal: .scale.combined(with: .opacity)
                            )
                        )
                    }
                }
            }
        }
        .animation(.default, value: selectedContent)
        /// Note: `onChange` modifier is called after view body is re-evaluated.
        .onChange(of: selectedContent, initial: true) { oldValue, newValue in
            print("selectedContent: \(oldValue.description) -> \(newValue.description)")
        }
        .overlay(alignment: .bottom) {
            Picker("", selection: $selectedContent) {
                ForEach(ContentType.allCases) {
                    Text($0.description)
                        .tag($0)
                }
            }
        }
        /// Workaround: Move .alert modifier outside of LazyVGrid content builder, and capture data value using an @State var.
        /// Note:  This workaround doesn't work if the .alert modifier is applied on a view inside the LazyVGrid's content builder.
        .alert("Alert", isPresented: $showAlertWithState, presenting: alertItem) { value in
            Button("\(value.0), \(value.1)") {
                print("dismissed state item \(String(value.1)) at offset \(value.0)")
            }
            Button("Dismiss") {
                print("dismissed state item \(String(value.1)) at offset \(value.0)")
            }
        }
    }
    
    private var items: [(offset: Int, element: String.Element)] {
        switch selectedContent {
        case .alphabet:
            alphabet
        case .numbers:
            numbers
        }
    }
}

#Preview {
    ContentView()
}
