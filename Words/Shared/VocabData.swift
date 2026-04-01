//
//  VocabData.swift
//  Words
//
//  Created by Julia Teleki on 3/31/26.
//

import Foundation

struct VocabWord: Identifiable, Hashable {
    let id = UUID()
    let word: String
    let definition: String?
    let synonyms: [String]

    init(word: String, definition: String?, synonyms: [String] = []) {
        self.word = word
        self.definition = definition
        self.synonyms = synonyms
    }
}

enum VocabData {
    static let vocab: [VocabWord] = [
        VocabWord(word: "abhor", definition: "Definition not provided.", synonyms: ["hate", "detest", "loathe", "despise"]),
        VocabWord(word: "absolve", definition: "Definition not provided.", synonyms: ["forgive", "pardon", "exonerate", "acquit"]),
        VocabWord(word: "antecedent", definition: "a word, phrase, or clause referred to by a pronoun", synonyms: ["precursor", "prior", "previous"]),
        VocabWord(word: "brocade", definition: "rich fabric with raised pattern", synonyms: ["fabric", "textile"]),
        VocabWord(word: "enormous", definition: "very large in size", synonyms: ["big", "huge", "immense", "massive"]),
        VocabWord(word: "clause", definition: "a grammatical unit that contains both a subject and a verb", synonyms: ["sentence part", "proposition"]),
        VocabWord(word: "coherence", definition: "the quality of being logical and consistent", synonyms: ["clarity", "consistency", "logic"]),
        VocabWord(word: "conjunction", definition: "a word that joins words, phrases, or clauses", synonyms: ["connector", "linker"]),
        VocabWord(word: "declarative", definition: "a sentence that makes a statement", synonyms: ["assertive"]),
        VocabWord(word: "exclamatory", definition: "a sentence that expresses strong feeling", synonyms: ["emphatic"]),
        VocabWord(word: "fragment", definition: "an incomplete sentence", synonyms: ["piece", "portion", "part"]),
        VocabWord(word: "hyperbole", definition: "an exaggerated statement", synonyms: ["exaggeration", "overstatement"]),
        VocabWord(word: "imperative", definition: "a sentence that gives a command", synonyms: ["command", "mandatory", "urgent"]),
        VocabWord(word: "interjection", definition: "a word that expresses emotion", synonyms: ["exclamation"]),
        VocabWord(word: "metaphor", definition: "a figure of speech that compares two things without using \"like\" or \"as\"", synonyms: ["analogy", "symbol"]),
        VocabWord(word: "noun", definition: "a word that names a person, place, thing, or idea", synonyms: ["name"]),
        VocabWord(word: "onomatopoeia", definition: "a word that imitates a sound", synonyms: ["sound word"]),
        VocabWord(word: "oxymoron", definition: "a figure of speech that combines contradictory terms", synonyms: ["contradiction"]),
        VocabWord(word: "paragraph", definition: "a distinct section of a piece of writing", synonyms: ["section"]),
        VocabWord(word: "predicate", definition: "the part of a sentence containing the verb and stating something about the subject", synonyms: ["verb phrase"]),
        VocabWord(word: "preposition", definition: "a word that shows the relationship of a noun or pronoun to another word", synonyms: ["relational word"]),
        VocabWord(word: "pronoun", definition: "a word that takes the place of a noun", synonyms: ["substitute noun"]),
        VocabWord(word: "simile", definition: "a figure of speech comparing two unlike things using \"like\" or \"as\"", synonyms: ["comparison"]),
        VocabWord(word: "subject", definition: "the person or thing that performs the action in a sentence", synonyms: ["topic"]),
        VocabWord(word: "syntax", definition: "the arrangement of words and phrases to create sentences", synonyms: ["structure", "grammar"]),
        VocabWord(word: "theme", definition: "the central topic or idea in a text", synonyms: ["topic", "motif"]),
        VocabWord(word: "verb", definition: "a word that expresses an action or state of being", synonyms: ["action word"])
    ]

    static let synonymsToWord: [String: VocabWord] = {
        var map: [String: VocabWord] = [:]
        for vw in vocab {
            for syn in vw.synonyms {
                map[syn.lowercased()] = vw
            }
            map[vw.word.lowercased()] = vw
        }
        return map
    }()

    static func suggestion(for typedWord: String) -> VocabWord? {
        let key = typedWord.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return synonymsToWord[key]
    }
}
