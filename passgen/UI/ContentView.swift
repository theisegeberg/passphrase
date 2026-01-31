import SwiftUI

struct ContentView: View {

    @Environment(\.colorScheme) var colorScheme
    @AppStorage("wordCount") var wordCount: Double = 4

    let passwordLengthRange: ClosedRange<Double> = 3...12
    let passwordLengthStep: Double = 1
    let generator = PasswordGenerator()

    @State var passwords: [Password] = []
    @State var generating: Bool = false
    @State var generatorTask: Task<Void, Never>? = nil

    func generate() {
        generatorTask?.cancel()
        generatorTask = Task {
            defer {
                withAnimation {
                    self.generating = false
                }
            }
            guard !Task.isCancelled else { return }
            await MainActor.run {
                self.generating = true
            }

            guard !Task.isCancelled else { return }
            let scoredPasswords = generator.generate(wordCount: Int(wordCount))

            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation {
                    self.passwords = scoredPasswords.suffix(5)
                }
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Slider(value: $wordCount.animation(), in: passwordLengthRange, step: passwordLengthStep) {
                    } minimumValueLabel: {
                        Text("Weaker").font(.caption)
                    } maximumValueLabel: {
                        Text("Stronger").font(.caption)
                    }
                    .onChange(of: wordCount) { oldValue, newValue in
                        withAnimation {
                            passwords.removeAll()
                        }
                    }

                    Text("\(Int(wordCount)) word(s) picked from a list of \(generator.words.count)")
                    Text("\(Int(entropyBits(forWordCount: Int(wordCount), fromList: generator.words.count))) bits of entropy").bold()
                    Text("\(entropyDescription(bits: Int(entropyBits(forWordCount: Int(wordCount), fromList: generator.words.count))))")

                    if generating {
                        ProgressView().id(UUID()).frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        Button(passwords.isEmpty ? "Generate" : "Clear") {
                            guard generating == false else {
                                return
                            }
                            if passwords.isEmpty {
                                generate()
                            } else {
                                withAnimation {
                                    passwords.removeAll()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                
                if passwords.isEmpty == false {
                    Section {
                        List {
                            ForEach(passwords) { password in
                                HStack {
                                    wordsToColorString(password.words)
                                        .font(.system(.headline, design: .monospaced, weight: .bold))
                                    Spacer()
                                }

                            }
                        }
                    }
                }
            }
            .navigationTitle("Passphrase")
        }
    }

    func wordsToColorString(_ strings: [String]) -> Text {
        zip(strings, Color.wongColors(scheme: colorScheme))
            .map { c in
                return Text(c.0).foregroundStyle(c.1)
            }
            .reduce(Text("")) { partialResult, text in
                partialResult + text + Text(" ")
            }
    }

    func entropyBits(forWordCount wordCount: Int, fromList listCount: Int) -> Double {
        guard listCount > 0 else { return 0.0 }
        return floor(log2(Double(listCount)) * Double(wordCount))
    }
}
