//
//  ContentView.swift
//  Words
//
//  Created by Julia Teleki on 3/30/26.
//

import SwiftUI

struct ContentView: View {
    // Static alphabetized array of VocabWord
    let vocab: [VocabWord] = VocabData.vocab.sorted { $0.word < $1.word }
    
    // Letters for the shortcut bar
    let letters: [String] = (65...90).map { String(UnicodeScalar($0)!) }
    
    // Dictionary grouping words by their starting letter
    var sectionedVocab: [String: [VocabWord]] {
        Dictionary(
            grouping: vocab,
            by: { word in
                guard let first = word.word.first else { return "#" }
                return String(first).uppercased()
            }
        )
    }
    
    // Sorted section titles for display
    var sortedSections: [String] {
        sectionedVocab.keys.sorted()
    }
    
    @State private var scrollTarget: String?
    
    var body: some View {
        NavigationStack {
            HStack(alignment: .top) {
                ScrollViewReader { proxy in
                    List {
                        ForEach(sortedSections, id: \.self) { section in
                            Section(header: Text(section)) {
                                ForEach(sectionedVocab[section] ?? [], id: \.self) { vocabWord in
                                    NavigationLink(value: vocabWord) {
                                        Text(vocabWord.word)
                                    }
                                }
                            }
                            .id(section) // Assign ID for scrolling
                        }
                    }
                    .listStyle(.grouped)
                    .onChange(of: scrollTarget) { target in
                        if let target, sectionedVocab[target] != nil {
                            withAnimation {
                                proxy.scrollTo(target, anchor: .top)
                            }
                        }
                    }
                    .navigationDestination(for: VocabWord.self) { vocabWord in
                        VocabWordDetailView(vocabWord: vocabWord)
                    }
                }
                // Shortcut bar
                GeometryReader { geometry in
                    VStack {
                        Spacer()
                        VStack(spacing: 2) {
                            ForEach(letters, id: \.self) { letter in
                                Button(action: {
                                    scrollTarget = letter
                                }) {
                                    Text(letter)
                                        .font(.headline)
                                        .foregroundColor(.accentColor)
                                        .frame(width: 28, height: 28)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        Spacer()
                    }
                    .frame(width: 36, height: geometry.size.height)
                }
                .frame(width: 36)
            }
            .navigationTitle("Vocabulary")
        }
    }
}

struct VocabWordDetailView: View {
    let vocabWord: VocabWord
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(vocabWord.word)
                .font(.largeTitle)
                .bold()
            
            if let definition = vocabWord.definition {
                Text(definition)
                    .font(.body)
            } else {
                Text("No definition available.")
                    .italic()
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle(vocabWord.word)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ContentView()
}
