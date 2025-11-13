import SwiftUI
import SwiftData

import SwiftUI

struct ScriptureScrollView: View {
    let scriptures: [(String, String)]
    var onScriptureChanged: ((Int) -> Void)?
    
    @AppStorage("hasSeenSwipeHint") private var hasSeenSwipeHint = false
    @State private var showSwipeHint = false
    
    var body: some View {
        ZStack {
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(scriptures.enumerated()), id: \.offset) { index, scripture in
                        ScriptureCard(reference: scripture.0, verse: scripture.1)
                            .containerRelativeFrame(.vertical)
                            .onAppear {
                                onScriptureChanged?(index)
                            }
                    }
                }
            }
            .scrollTargetLayout()
            
            // Swipe up hint
            if showSwipeHint {
                VStack {
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Image(systemName: "chevron.up")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .offset(y: showSwipeHint ? 0 : 10)
                            .animation(
                                .easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true),
                                value: showSwipeHint
                            )
                        
                        Text("Swipe up for more")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .padding(.bottom)
//                    .background(
//                        Capsule()
//                            .fill(.ultraThinMaterial)
//                            .overlay(
//                                Capsule()
//                                    .stroke(.white.opacity(0.3), lineWidth: 1)
//                            )
//                    )
//                    .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                    .padding(.bottom, 60)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            if !hasSeenSwipeHint {
                // Show hint after a brief delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        showSwipeHint = true
                    }
                }
                
                // Hide hint after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSwipeHint = false
                    }
                    hasSeenSwipeHint = true
                }
            }
        }
    }
}

//struct ScriptureScrollView: View {
//    let scriptures: [(String, String)]
//    var onScriptureChanged: ((Int) -> Void)?
//    
//    var body: some View {
//        ScrollView(.vertical) {
//            LazyVStack(spacing: 0) {
//                ForEach(Array(scriptures.enumerated()), id: \.offset) { index, scripture in
//                    ScriptureCard(reference: scripture.0, verse: scripture.1)
//                                            .containerRelativeFrame(.vertical)
//                                            .onAppear {
//                                                onScriptureChanged?(index)
//                                            }
//                }
//            }
//        }
//        .scrollTargetLayout()
//    }
//}

//struct ScriptureCard: View {
//    let reference: String
//    let verse: String
//    
//    var body: some View {
//        VStack {
//            Spacer()
//            
//            VStack(spacing: 12) {
//                Text("“\(verse)”")
//                    .font(.headline)
//                    .foregroundColor(.white)
//                    .multilineTextAlignment(.center)
//                
//                Text(reference)
//                    .font(.subheadline)
//                    .foregroundColor(.white.opacity(0.8))
//                
//                HStack(spacing: 24) {
//                    ShareLink("", item: "\(verse)\n\(reference)")
//                        .font(.system(size: 22))
//                        .foregroundColor(.white)
//                        .padding(12)
//                    
//                    Button {
//                        // Favorite
//                    } label: {
//                        Image(systemName: "heart")
//                            .font(.system(size: 22))
//                            .foregroundColor(.white)
//                            .padding(12)
//                    }
//                }
//            }
//            .frame(width: 320)
//            .padding(.horizontal)
//            
//            Spacer()
//        }
//    }
//}

struct ScriptureCard: View {
    @Environment(\.modelContext) private var modelContext
    let reference: String
    let verse: String
    
    @State private var isFavorited = false
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 12) {
                Text("\(verse)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                Text(reference)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                
                HStack(spacing: 24) {
                    ShareLink("", item: "\(verse)\n\(reference)")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                        .padding(12)
                    
                    Button {
                        toggleFavorite()
                    } label: {
                        Image(systemName: isFavorited ? "heart.fill" : "heart")
                            .font(.system(size: 22))
                            .foregroundColor(isFavorited ? .red : .white)
                            .padding(12)
                    }
                }
            }
            .frame(width: 320)
            .padding(.horizontal)
            
            Spacer()
        }
        .onAppear {
            checkIfFavorited()
        }
    }
    
    private func checkIfFavorited() {
        let ref = reference
        let descriptor = FetchDescriptor<FavoriteScripture>(
            predicate: #Predicate { $0.reference == ref }
        )
        
        let results = try? modelContext.fetch(descriptor)
        isFavorited = !(results?.isEmpty ?? true)
    }
    
    private func toggleFavorite() {
        let ref = reference
        let descriptor = FetchDescriptor<FavoriteScripture>(
            predicate: #Predicate { $0.reference == ref }
        )
        
        if let existing = try? modelContext.fetch(descriptor).first {
            // Remove from favorites
            modelContext.delete(existing)
            isFavorited = false
        } else {
            // Add to favorites
            let favorite = FavoriteScripture(
                reference: reference,
                text: verse
            )
            modelContext.insert(favorite)
            isFavorited = true
        }
        
        try? modelContext.save()
    }
}

