import SwiftUI

// MARK: - WordCloud

struct WordCloud: View {
    let words: [SharedWord]
    let onWordTap: (SharedWord) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 150), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(words) { word in
                    WordChip(word: word) {
                        onWordTap(word)
                    }
                }
            }
            .padding(16)
        }
    }
}

// MARK: - WordChip

struct WordChip: View {
    let word: SharedWord
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                onTap()
            }
        }) {
            VStack(spacing: 4) {
                Text(word.word)
                    .font(.system(size: 18, weight: .medium, design: .serif))
                    .foregroundColor(Color(hex: "22211F"))

                Text(word.romaji)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(Color(hex: "8c867d"))
            }
            .frame(minWidth: 90)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: "faf8f4"))
            .cornerRadius(12)
            .shadow(color: Color(hex: "22211f").opacity(0.03), radius: 2, x: 0, y: 1)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "e4ded4"), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.92 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Previews

#Preview("WordCloud") {
    let sampleWords = [
        SharedWord(id: "1", word: "猫", romaji: "neko", meaning: "cat", audioFileName: nil),
        SharedWord(id: "2", word: "犬", romaji: "inu", meaning: "dog", audioFileName: nil),
        SharedWord(id: "3", word: "鳥", romaji: "tori", meaning: "bird", audioFileName: nil),
        SharedWord(id: "4", word: "魚", romaji: "sakana", meaning: "fish", audioFileName: nil),
        SharedWord(id: "5", word: "花", romaji: "hana", meaning: "flower", audioFileName: nil),
        SharedWord(id: "6", word: "木", romaji: "ki", meaning: "tree", audioFileName: nil),
    ]

    WordCloud(words: sampleWords) { word in
        print("Tapped: \(word.word)")
    }
}

#Preview("WordChip") {
    let sampleWord = SharedWord(
        id: "1",
        word: "猫",
        romaji: "neko",
        meaning: "cat",
        audioFileName: nil
    )

    WordChip(word: sampleWord) {
        print("Tapped!")
    }
    .padding()
}
