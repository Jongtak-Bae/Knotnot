import SwiftUI

// Wrapper for UITextView to enable reliable focus and cursor visibility
struct TextEditorRepresentable: UIViewRepresentable {
    @Binding var text: String
    @FocusState var isFocused: Bool
    var placeholder: String // Placeholder parameter
    
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
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: TextEditorRepresentable
        
        init(_ parent: TextEditorRepresentable) {
            self.parent = parent
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
    }
}

struct NoteSheet: View {
    @Binding var userText: String
    @Binding var isPresented: Bool
    let onSave: (String) -> Void
    @State private var draftText: String = ""
    @FocusState private var isTextEditorFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack {
                ZStack(alignment: .topLeading) {
                    TextEditorRepresentable(
                        text: $draftText,
                        placeholder: "Enter your note here..."
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
                
                Spacer()
            }
            //.navigationTitle("Add Note")
            .padding(.vertical)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        onSave(draftText)
                        isPresented = false
                    }) {
                        Text("Save")
                            .padding(4)
                            .padding(.horizontal, 4)
                            .foregroundStyle(Color.white)
                            .background(Color(hex: "#5D00FF"))
                            .clipShape(Capsule())
                    }
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isTextEditorFocused = true // Trigger focus to show keyboard and cursor
                }
            }
        }
    }
}

struct NoteSheet_Previews: PreviewProvider {
    @State static var text = ""
    @State static var isPresented = true
    
    static var previews: some View {
        NoteSheet(
            userText: $text,
            isPresented: $isPresented,
            onSave: { _ in }
        )
    }
}
