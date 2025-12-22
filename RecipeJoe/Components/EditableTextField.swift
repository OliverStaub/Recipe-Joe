//
//  EditableTextField.swift
//  RecipeJoe
//
//  Long-press-to-edit text field component with sheet editor
//

import SwiftUI

struct EditableTextField: View {
    let value: String
    let placeholder: String
    let title: String
    let onSave: (String) -> Void

    var textStyle: Font = .body
    var textWeight: Font.Weight = .regular
    var textColor: Color = .primary
    var multiline: Bool = false

    @State private var showEditSheet = false
    @State private var editValue = ""

    var body: some View {
        Text(value.isEmpty ? placeholder : value)
            .font(textStyle)
            .fontWeight(textWeight)
            .foregroundStyle(value.isEmpty ? .secondary : textColor)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onLongPressGesture {
                editValue = value
                showEditSheet = true
            }
            .sheet(isPresented: $showEditSheet) {
                TextFieldEditSheet(
                    title: title,
                    value: $editValue,
                    multiline: multiline,
                    onSave: {
                        showEditSheet = false
                        onSave(editValue)
                    },
                    onCancel: {
                        showEditSheet = false
                    }
                )
                .presentationDetents([multiline ? .medium : .height(200)])
            }
    }
}

// MARK: - Text Field Edit Sheet

struct TextFieldEditSheet: View {
    let title: String
    @Binding var value: String
    var multiline: Bool = false
    let onSave: () -> Void
    let onCancel: () -> Void

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
                        .onSubmit {
                            onSave()
                        }
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
