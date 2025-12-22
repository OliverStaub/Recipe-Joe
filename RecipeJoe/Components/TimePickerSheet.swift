//
//  TimePickerSheet.swift
//  RecipeJoe
//
//  Sheet for picking time in hours and minutes
//

import SwiftUI

struct TimePickerSheet: View {
    let title: String
    @Binding var minutes: Int
    let onSave: () -> Void
    let onCancel: () -> Void

    @State private var hours: Int = 0
    @State private var mins: Int = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Set \(title) Time")
                    .font(.headline)

                HStack(spacing: 0) {
                    Picker("Hours", selection: $hours) {
                        ForEach(0..<24) { h in
                            Text("\(h) hr").tag(h)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100)

                    Picker("Minutes", selection: $mins) {
                        ForEach(0..<60) { m in
                            Text("\(m) min").tag(m)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100)
                }

                Spacer()
            }
            .padding()
            .onAppear {
                hours = minutes / 60
                mins = minutes % 60
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        minutes = hours * 60 + mins
                        onSave()
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.terracotta)
                }
            }
        }
    }
}
