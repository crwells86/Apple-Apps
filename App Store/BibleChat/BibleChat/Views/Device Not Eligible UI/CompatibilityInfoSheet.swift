import SwiftUI

struct CompatibilityInfoSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Limited Features Available")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("""
                                            Holy Bible Chat is designed to help you grow in faith through personal reflection, meaningful study, and private conversations with Scripture — all safely on your device.
                                            """)
                        
                        Text("""
                                            Some advanced experiences — like generating personalized devotionals and chatting directly with the Holy Bible for deeper insights — require newer devices with enhanced on-device capabilities.
                                            """)
                        
                        Text("""
                                            You can still enjoy the complete King James Version Bible for free — read, search, share, and bookmark verses without an account or internet connection.
                                            """)
                        
                        Text("""
                                            If you’d like to access all the interactive features of Holy Bible Chat, please use one of the supported devices listed below.
                                            """)
                    }
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineSpacing(5)
                    
                    
                    Divider()
                        .padding(.vertical)
                    
                    Text("Compatible Devices")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Group {
                            Text("• iPhone 17, 17 Pro, 17 Pro Max, 17 Air")
                            Text("• iPhone 16e, 16, 16 Plus, 16 Pro, 16 Pro Max")
                            Text("• iPhone 15 Pro, 15 Pro Max")
                            //                            Text("• iPad Pro (M1 and later)")
                            //                            Text("• iPad Air (M1 and later)")
                            //                            Text("• iPad mini (A17 Pro)")
                        }
                        //                        Group {
                        //                            Text("• MacBook Air (M1 and later)")
                        //                            Text("• MacBook Pro (M1 and later)")
                        //                            Text("• iMac (M1 and later)")
                        //                            Text("• Mac mini (M1 and later)")
                        //                            Text("• Mac Studio (M1 Max and later)")
                        //                            Text("• Mac Pro (M2 Ultra)")
                        //                            Text("• Apple Vision Pro (M2)")
                        //                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    Spacer(minLength: 30)
                    
                    Button(action: { dismiss() }) {
                        Text("Continue to Free Bible")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .navigationTitle("Compatibility Notice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
