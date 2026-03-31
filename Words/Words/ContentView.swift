//
//  ContentView.swift
//  Words
//
//  Created by Julia Teleki on 3/30/26.
//

import SwiftUI

struct VocabWord: Identifiable, Hashable {
    let id = UUID()
    let word: String
    let definition: String?
}

struct ContentView: View {
    // Static alphabetized array of VocabWord
    let vocab: [VocabWord] = [
        VocabWord(word: "abhor", definition: "Definition not provided."),
        VocabWord(word: "absolve", definition: "Definition not provided."),
        VocabWord(word: "antecedent", definition: "a word, phrase, or clause referred to by a pronoun"),
        VocabWord(word: "brocade", definition: "rich fabric with raised pattern"),
        VocabWord(word: "clause", definition: "a grammatical unit that contains both a subject and a verb"),
        VocabWord(word: "coherence", definition: "the quality of being logical and consistent"),
        VocabWord(word: "conjunction", definition: "a word that joins words, phrases, or clauses"),
        VocabWord(word: "declarative", definition: "a sentence that makes a statement"),
        VocabWord(word: "exclamatory", definition: "a sentence that expresses strong feeling"),
        VocabWord(word: "fragment", definition: "an incomplete sentence"),
        VocabWord(word: "hyperbole", definition: "an exaggerated statement"),
        VocabWord(word: "imperative", definition: "a sentence that gives a command"),
        VocabWord(word: "interjection", definition: "a word that expresses emotion"),
        VocabWord(word: "metaphor", definition: "a figure of speech that compares two things without using \"like\" or \"as\""),
        VocabWord(word: "noun", definition: "a word that names a person, place, thing, or idea"),
        VocabWord(word: "onomatopoeia", definition: "a word that imitates a sound"),
        VocabWord(word: "oxymoron", definition: "a figure of speech that combines contradictory terms"),
        VocabWord(word: "paragraph", definition: "a distinct section of a piece of writing"),
        VocabWord(word: "predicate", definition: "the part of a sentence containing the verb and stating something about the subject"),
        VocabWord(word: "preposition", definition: "a word that shows the relationship of a noun or pronoun to another word"),
        VocabWord(word: "pronoun", definition: "a word that takes the place of a noun"),
        VocabWord(word: "simile", definition: "a figure of speech comparing two unlike things using \"like\" or \"as\""),
        VocabWord(word: "subject", definition: "the person or thing that performs the action in a sentence"),
        VocabWord(word: "syntax", definition: "the arrangement of words and phrases to create sentences"),
        VocabWord(word: "theme", definition: "the central topic or idea in a text"),
        VocabWord(word: "verb", definition: "a word that expresses an action or state of being")
    ].sorted { $0.word < $1.word }
    
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
