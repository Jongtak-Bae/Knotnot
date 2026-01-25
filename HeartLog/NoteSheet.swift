import SwiftUI

// Wrapper for UITextView to enable reliable focus and cursor visibility
struct TextEditorRepresentable: UIViewRepresentable {
    @Binding var text: String
    @FocusState var isFocused: Bool
    var placeholder: String // Placeholder parameter
    var characterLimit: Int? = nil
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isScrollEnabled = true
        textView.isEditable = true
        textView.isUserInteractionEnabled = true
        textView.font = .systemFont(ofSize: 17) // Match SwiftUI TextEditor default
        textView.textColor = .label
        textView.backgroundColor = .clear
        textView.delegate = context.coordinator
        // Set text container inset for consistent alignment
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 5, bottom: 8, right: 5)
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // Only update text if it has changed to prevent unnecessary refreshes
        if uiView.text != text {
            let wasFirstResponder = uiView.isFirstResponder
            uiView.text = text
            // Restore first responder status if it was active to prevent keyboard dismissal
            if wasFirstResponder && !uiView.isFirstResponder {
                uiView.becomeFirstResponder()
            }
        }
        // Sync focus state, but avoid forcing resignation unless necessary
        if isFocused && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self, characterLimit: characterLimit)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: TextEditorRepresentable
        var characterLimit: Int?

        init(_ parent: TextEditorRepresentable, characterLimit: Int?) {
            self.parent = parent
            self.characterLimit = characterLimit
        }
        
        func textViewDidChange(_ textView: UITextView) {
            // Update binding only when text changes
            parent.text = textView.text
            // Ensure focus state remains true while editing
            parent.isFocused = true
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            // Ensure focus state is updated when editing begins
            parent.isFocused = true
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            // Update focus state when editing ends
            parent.isFocused = false
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            guard let limit = characterLimit else { return true }

            let currentText = textView.text ?? ""
            guard let stringRange = Range(range, in: currentText) else { return true }
            let updatedText = currentText.replacingCharacters(in: stringRange, with: text)

            if updatedText.count > limit {
                // Provide haptic feedback
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                return false
            }

            return true
        }
    }
}

struct NoteSheet: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @EnvironmentObject private var noteAccessManager: NoteAccessManager
    @Binding var userText: String
    @Binding var isPresented: Bool
    @Binding var selectedEmotions: Set<String>
    let onSave: (String) -> Void
    @State private var draftText: String = ""
    @State private var draftEmotions: Set<String> = []
    @State private var showPaywall: Bool = false
    @State private var showCharacterLimitError = false
    @State private var showUpgradePrompt = false
    @FocusState private var isTextEditorFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                ZStack(alignment: .topLeading) {
                    TextEditorRepresentable(
                        text: $draftText,
                        placeholder: "Enter your note here...",
                        characterLimit: noteAccessManager.characterLimit
                    )
                    .frame(minHeight: 200)
                    .padding(.horizontal, 10) // Match text container inset
                    .focused($isTextEditorFocused)
                    
                    // Placeholder text overlay, hidden only when text is present
                    if draftText.isEmpty {
                        Text("Enter your note here...")
                            .font(.system(size: 17)) // Match UITextView font
                            .foregroundColor(.gray.opacity(0.5))
                            .padding(.top, 8) // Match text container inset top
                            .padding(.leading, 15) // Match text container inset left + view padding
                            .padding(.horizontal, 5) // Additional padding for alignment
                            .allowsHitTesting(false) // Prevent interaction with placeholder
                    }
                }
//                .background(
//                    RoundedRectangle(cornerRadius: 10)
//                        .stroke(Color.gray.opacity(0.5))
//                )
                .padding(.horizontal)

                // Character counter (only show if limit exists)
                if let limit = noteAccessManager.characterLimit {
                    HStack {
                        Spacer()
                        Text("\(draftText.count) / \(limit)")
                            .font(.caption)
                            .foregroundColor(colorForCharacterCount())
                            .padding(.trailing)
                    }
                    .padding(.top, 4)
                }

                // Emotion Tags
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 4) {
                        Text("How are you feeling?")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.primary.opacity(0.7))
                        if !purchaseManager.isPremium {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundColor(Color(hex: "#A640BC"))
                        }
                    }
                    .padding(.horizontal, 15)

                    if purchaseManager.isPremium {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(["Anger", "Sadness", "Misunderstanding", "Disappointment", "Avoidance"], id: \.self) { emotion in
                                    EmotionChip(
                                        emotion: emotion,
                                        isSelected: draftEmotions.contains(emotion),
                                        onTap: {
                                            if draftEmotions.contains(emotion) {
                                                draftEmotions.remove(emotion)
                                            } else {
                                                draftEmotions.insert(emotion)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 15)
                        }
                    } else {
                        Button(action: {
                            showPaywall = true
                        }) {
                            HStack {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 14))
                                Text("Unlock Emotion Tags")
                                    .font(.system(size: 17, weight: .medium))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "#A640BC"), Color(hex: "#D896FF")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 15)
                    }
                }
                .padding(.top, 20)

                Spacer()
            }
            //.navigationTitle("Add Note")
            .padding(.vertical)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        if noteAccessManager.canSaveNote(withLength: draftText.count) {
                            selectedEmotions = draftEmotions
                            onSave(draftText)
                            isPresented = false
                        } else {
                            showCharacterLimitError = true
                        }
                    }) {
                        Text("Save")
                            .padding(4)
                            .padding(.horizontal, 4)
                            .foregroundStyle(Color.white)
                            .background(.purple)
                            .clipShape(Capsule())
                    }
                    .disabled(!noteAccessManager.canSaveNote(withLength: draftText.count))
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                        isTextEditorFocused = false // Ensure keyboard is dismissed
                    }
                    .foregroundStyle(Color.primary)
                }
            }
            .onAppear {
                draftText = userText
                draftEmotions = selectedEmotions
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextEditorFocused = true // Trigger focus to show keyboard and cursor
                }
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView(feature: .emotionTags)
                    .environmentObject(purchaseManager)
            }
            .sheet(isPresented: $showUpgradePrompt) {
                PaywallView(feature: .unlimitedNotes)
                    .environmentObject(purchaseManager)
            }
            .alert("Character Limit Reached", isPresented: $showCharacterLimitError) {
                Button("Upgrade to Premium") {
                    showUpgradePrompt = true
                }
                Button("OK", role: .cancel) { }
            } message: {
                Text("Free users can write up to 200 characters. Upgrade to Premium for unlimited notes.")
            }
        }
    }

    private func colorForCharacterCount() -> Color {
        guard let limit = noteAccessManager.characterLimit else { return .secondary }
        let count = draftText.count
        let percentage = Double(count) / Double(limit)

        if percentage >= 1.0 { return .red }
        if percentage >= 0.9 { return .orange }
        return .secondary
    }
}

struct NoteSheet_Previews: PreviewProvider {
    @State static var text = ""
    @State static var isPresented = true
    @State static var emotions: Set<String> = []

    static var previews: some View {
        NoteSheet(
            userText: $text,
            isPresented: $isPresented,
            selectedEmotions: $emotions,
            onSave: { _ in }
        )
    }
}

// MARK: - EmotionChip (Shared Component)
struct EmotionChip: View {
    let emotion: String
    let isSelected: Bool
    let onTap: () -> Void

    private var emotionIcon: String {
        switch emotion {
        case "Anger": return "flame.fill"
        case "Sadness": return "cloud.rain.fill"
        case "Misunderstanding": return "bubble.left.and.exclamationmark.bubble.right.fill"
        default: return "circle.fill"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if !isSelected {
                    Text("+")
                        .font(.system(size: 14, weight: .medium))
                }
                Text(emotion)
                    .font(.system(size: 13))
                    .tracking(-0.08)
            }
            .foregroundColor(isSelected ? Color(hex: "#9c36b2") : Color(hex: "#7f809e"))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color(hex: "#9c36b2").opacity(0.2) : Color.clear)
                    .overlay(
                        Capsule()
                            .stroke(Color(hex: "#b0b0c9"), lineWidth: isSelected ? 0 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
