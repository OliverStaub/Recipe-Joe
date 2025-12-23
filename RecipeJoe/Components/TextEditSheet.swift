//
//  TextEditSheet.swift
//  RecipeJoe
//
//  Sheet for editing a single text value
//

import SwiftUI

struct TextEditSheet: View {
    let title: String
    @Binding var value: String
    let onSave: () -> Void
    let onCancel: () -> Void
    var multiline: Bool = false

    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if multiline {
                    TextEditor(text: $value)
                        .focused($isFocused)
                        .frame(minHeight: 150)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    TextField(title, text: $value)
                        .textFieldStyle(.roundedBorder)
                        .focused($isFocused)
                }

                Spacer()
            }
            .padding()
            .onAppear { isFocused = true }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.terracotta)
                }
            }
        }
    }
}
