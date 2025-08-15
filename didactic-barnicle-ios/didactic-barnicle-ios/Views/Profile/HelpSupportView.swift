import SwiftUI
import MessageUI

struct HelpSupportView: View {
    @State private var showingMailComposer = false
    @State private var showingFAQ = false
    
    var body: some View {
        Form {
            Section(header: Text("Get Help")) {
                NavigationLink(destination: FAQView()) {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.blue)
                        Text("Frequently Asked Questions")
                    }
                }
                
                NavigationLink(destination: TutorialView()) {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundColor(.green)
                        Text("How to Play")
                    }
                }
                
                NavigationLink(destination: TroubleshootingView()) {
                    HStack {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .foregroundColor(.orange)
                        Text("Troubleshooting")
                    }
                }
            }
            
            Section(header: Text("Contact Us")) {
                Button(action: {
                    if MFMailComposeViewController.canSendMail() {
                        showingMailComposer = true
                    }
                }) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                        Text("Email Support")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
                
                Link(destination: URL(string: "https://twitter.com/artreasurehunt")!) {
                    HStack {
                        Image(systemName: "bubble.left.fill")
                            .foregroundColor(.blue)
                        Text("Twitter Support")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Legal")) {
                NavigationLink(destination: TermsOfServiceView()) {
                    Text("Terms of Service")
                }
                
                NavigationLink(destination: PrivacyPolicyView()) {
                    Text("Privacy Policy")
                }
                
                NavigationLink(destination: LicensesView()) {
                    Text("Open Source Licenses")
                }
            }
            
            Section(header: Text("App Info")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0")
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("Build")
                    Spacer()
                    Text(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingMailComposer) {
            MailComposerView(
                subject: "AR Treasure Hunt Support",
                recipients: ["support@artreasurehunt.com"]
            )
        }
    }
}

struct FAQView: View {
    let faqs = [
        FAQ(question: "How do I create treasures?", answer: "Tap the + button on the map screen, place your treasure in AR, add a description and hints, then save it for others to find!"),
        FAQ(question: "What are points for?", answer: "Points help you level up and unlock achievements. You earn points by finding treasures, creating popular treasures, and completing challenges."),
        FAQ(question: "How do friend requests work?", answer: "You can send friend requests by username. Once accepted, you can see each other's treasures and compete on leaderboards."),
        FAQ(question: "Is my location shared?", answer: "Your exact location is never shared. You can optionally share approximate location with friends in privacy settings."),
        FAQ(question: "How do I report inappropriate content?", answer: "Long press on any treasure or user profile to report inappropriate content. Our team reviews all reports within 24 hours.")
    ]
    
    var body: some View {
        List(faqs) { faq in
            DisclosureGroup {
                Text(faq.answer)
                    .font(.footnote)
                    .padding(.vertical, 8)
            } label: {
                Text(faq.question)
                    .font(.headline)
            }
        }
        .navigationTitle("FAQ")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FAQ: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

struct TutorialView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                TutorialSection(
                    title: "Finding Treasures",
                    icon: "map.fill",
                    steps: [
                        "Open the map to see nearby treasures",
                        "Walk to a treasure location",
                        "Tap 'Start Hunt' when you're close",
                        "Use AR to find and collect the treasure",
                        "Earn points and achievements!"
                    ]
                )
                
                TutorialSection(
                    title: "Creating Treasures",
                    icon: "plus.circle.fill",
                    steps: [
                        "Tap the + button on the map",
                        "Choose a location for your treasure",
                        "Place it in AR view",
                        "Add description and hints",
                        "Set difficulty and publish"
                    ]
                )
                
                TutorialSection(
                    title: "Social Features",
                    icon: "person.2.fill",
                    steps: [
                        "Add friends by username",
                        "View friend leaderboards",
                        "Share treasures with friends",
                        "Compete in challenges",
                        "Send messages and gifts"
                    ]
                )
            }
            .padding()
        }
        .navigationTitle("How to Play")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TutorialSection: View {
    let title: String
    let icon: String
    let steps: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                Text(title)
                    .font(.headline)
            }
            
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top) {
                    Text("\(index + 1).")
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    Text(step)
                        .font(.subheadline)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

struct TroubleshootingView: View {
    var body: some View {
        List {
            Section(header: Text("Common Issues")) {
                TroubleshootingRow(
                    issue: "AR not working",
                    solution: "Make sure you've granted camera permissions and you're in a well-lit area"
                )
                
                TroubleshootingRow(
                    issue: "Can't see treasures on map",
                    solution: "Check your internet connection and location permissions"
                )
                
                TroubleshootingRow(
                    issue: "App crashes frequently",
                    solution: "Try reinstalling the app or freeing up device storage"
                )
            }
            
            Section(header: Text("Reset Options")) {
                Button("Clear Cache") {
                }
                .foregroundColor(.orange)
                
                Button("Reset Tutorial") {
                }
                .foregroundColor(.orange)
                
                Button("Reset All Settings") {
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Troubleshooting")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TroubleshootingRow: View {
    let issue: String
    let solution: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(issue)
                .font(.headline)
            Text(solution)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            Text("Terms of Service content here...")
                .padding()
        }
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            Text("Privacy Policy content here...")
                .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LicensesView: View {
    var body: some View {
        List {
            Text("Open source licenses will be listed here")
        }
        .navigationTitle("Open Source Licenses")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MailComposerView: UIViewControllerRepresentable {
    let subject: String
    let recipients: [String]
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setSubject(subject)
        composer.setToRecipients(recipients)
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposerView
        
        init(_ parent: MailComposerView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.dismiss()
        }
    }
}