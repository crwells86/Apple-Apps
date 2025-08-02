import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var step = 1
    @Namespace private var animationNamespace
    
    @Environment(\.modelContext) private var modelContext
    @Environment(SubscriptionController.self) var subscriptionController
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                Group {
                    switch step {
                    case 1:
                        OnboardingStepView(
                            title: "Track Your Hours",
                            subtitle: "Log time manually or use the flip clock for visual tracking.",
                            imageSystemName: "clock"
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        
                    case 2:
                        OnboardingStepView(
                            title: "See What You’ve Earned",
                            subtitle: "View total earnings by week or month — automatically calculated for you.",
                            imageSystemName: "chart.bar.doc.horizontal"
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                        
                    case 3:
                        OnboardingStepView(
                            title: "Export Invoices Fast",
                            subtitle: "Create and export polished PDF invoices with just a few taps.",
                            imageSystemName: "doc.richtext"
                        )
                        .transition(.move(edge: .leading).combined(with: .opacity))
                        
                    case 4:
                        CreateJobStep {
                            withAnimation {
                                hasCompletedOnboarding = true
                            }
                        }
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                        
                    default:
                        EmptyView()
                    }
                }
                .animation(.easeIn(duration: 0.42), value: step)
                
                Spacer()
                
                if step < 4 {
                    Button(action: {
                        withAnimation {
                            step += 1
                        }
                    }) {
                        Text("Next")
                            .fontWeight(.semibold)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 12)
                            .background(Color.accentColor)
                            .foregroundStyle(Color.white)
                            .clipShape(Capsule())
                    }
                    .transition(.opacity)
                }
            }
            .padding()
        }
    }
}

struct OnboardingStepView: View {
    let title: String
    let subtitle: String
    let imageSystemName: String?
    
    var body: some View {
        VStack(spacing: 24) {
            if let imageName = imageSystemName {
                Image(systemName: imageName)
                    .font(.system(size: 60))
                    .foregroundStyle(.accent)
                    .transition(.scale)
            }
            Text(title)
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .transition(.opacity)
            
            Text(subtitle)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .transition(.opacity)
        }
        .padding(.horizontal)
    }
}



import SwiftUI

struct CreateJobStep: View {
    @Environment(\.modelContext) private var modelContext
    @State private var title = ""
    @State private var company = ""
    @State private var rate = ""
    
    @State private var showPaywall = false
    var onComplete: () -> Void
    
    var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        Decimal(string: rate) != nil
    }
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Create Your First Job")
                    .font(.title2.bold())
                
                TextField("Job Title", text: $title)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.jobTitle)
                
                TextField("Company (optional)", text: $company)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.organizationName)
                
                TextField("Hourly Rate", text: $rate)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
            
            Button(action: {
                guard isFormValid else { return }
                
                let job = Job(
                    title: title,
                    company: company.isEmpty ? nil : company,
                    hourlyRate: Decimal(string: rate)!
                )
                modelContext.insert(job)
                
                showPaywall = true
            }) {
                Text("Create Job")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .disabled(!isFormValid)
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
        .padding()
        .sheet(isPresented: $showPaywall, onDismiss: {
            onComplete()
        }) {
            PaywallView()
        }
    }
}
