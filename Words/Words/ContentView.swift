//
//  ContentView.swift
//  Words
//
//  Created by Julia Teleki on 3/30/26.
//

import SwiftUI

struct ContentView: View {
    // This will hold your vocabulary words; leave empty for now.
    let vocab: [String] = []
    
    // Letters for the shortcut bar
    let letters: [String] = (65...90).map { String(UnicodeScalar($0)!) }
    
    // Dictionary grouping words by their starting letter
    var sectionedVocab: [String: [String]] {
        Dictionary(
            grouping: vocab,
            by: { word in
                guard let first = word.first else { return "#" }
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
        HStack(alignment: .top) {
            ScrollViewReader { proxy in
                List {
                    ForEach(sortedSections, id: \.self) { section in
                        Section(header: Text(section)) {
                            ForEach(sectionedVocab[section] ?? [], id: \.self) { word in
                                Text(word)
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
            }
            // Shortcut bar
            VStack(spacing: 2) {
                ForEach(letters, id: \.self) { letter in
                    Button(action: {
                        scrollTarget = letter
                    }) {
                        Text(letter)
                            .font(.caption2)
                            .foregroundColor(.accentColor)
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

#Preview {
    ContentView()
}
