import Foundation
import AVFoundation
import Combine

class PracticeViewModel: NSObject, ObservableObject {
    // MARK: - Published Properties
    
    @Published var selectedLanguage = "English"
    @Published var availableLanguages = ["English", "Spanish", "French", "Japanese", "Chinese", "German"]
    @Published var currentPrompt = "Introduce yourself and describe your hobbies in a few sentences."
    
    @Published var isAnalyzing = false
    @Published var hasFeedback = false
    @Published var transcript = ""
    @Published var wordsPerMinute = 0
    @Published var pronunciationFeedback = ""
    @Published var grammarFeedback = ""
    
    @Published var showError = false
    @Published var errorMessage = ""
    
    // MARK: - Private Properties
    
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    var lastRecordingURL: URL?
    
    private var prompts: [String: [String]] = [
        "English": [
            "Describe your favorite vacation destination and explain why you enjoy it.",
            "Talk about a book or movie that influenced you and why it made an impact.",
            "Describe your morning routine from the moment you wake up.",
            "If you could have dinner with anyone, living or dead, who would it be and why?",
            "Describe a skill you would like to learn and explain why it interests you.",
            "Talk about a challenge you've overcome and how it changed you."
        ],
        "Spanish": [
            "Habla sobre tu comida favorita y cómo se prepara.",
            "Describe tu ciudad natal y qué te gusta de ella.",
            "¿Cómo sería tu día perfecto? Describe todas las actividades.",
            "Habla sobre un viaje memorable que hayas hecho.",
            "Describe a tu familia y las tradiciones que tienen juntos.",
            "Si pudieras vivir en cualquier país, ¿cuál elegirías y por qué?"
        ],
        "French": [
            "Décrivez votre plat préféré et comment on le prépare.",
            "Parlez de vos projets pour l'avenir.",
            "Décrivez votre film ou livre préféré et pourquoi vous l'aimez.",
            "Si vous pouviez voyager n'importe où, où iriez-vous et pourquoi?",
            "Parlez de votre routine quotidienne.",
            "Décrivez votre saison préférée et expliquez pourquoi vous l'aimez."
        ],
        "Japanese": [
            "あなたの趣味について話してください。",
            "あなたの故郷について説明してください。",
            "好きな食べ物は何ですか？なぜそれが好きですか？",
            "週末は何をするのが好きですか？",
            "あなたの将来の目標は何ですか？",
            "日本に行ったら、どこを訪れたいですか？"
        ],
        "Chinese": [
            "请介绍一下你自己和你的家人。",
            "描述一下你的家乡。",
            "谈谈你最喜欢的季节，为什么你喜欢它？",
            "如果你有一天的自由时间，你会做什么？",
            "描述一下你最喜欢的食物。",
            "你的业余爱好是什么？为什么你喜欢这些活动？"
        ],
        "German": [
            "Beschreibe deinen typischen Tag.",
            "Was sind deine Hobbys und warum magst du sie?",
            "Sprich über deinen Lieblingsfilm oder dein Lieblingsbuch.",
            "Welche Reiseziele möchtest du in der Zukunft besuchen?",
            "Beschreibe deine Stadt und was du daran magst oder nicht magst.",
            "Was hast du am Wochenende gemacht?"
        ]
    ]
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        generateRandomPrompt()
    }
    
    // MARK: - Public Methods
    
    func checkMicrophonePermission() {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                break
            case .denied:
                showError(message: "Microphone access denied. Please enable microphone access in Settings.")
            case .undetermined:
                AVAudioApplication.requestRecordPermission { [weak self] allowed in
                    DispatchQueue.main.async {
                        if !allowed {
                            self?.showError(message: "Microphone access is required for recording.")
                        }
                    }
                }
            @unknown default:
                break
            }
        } else {
            // Fallback for iOS 16 and below
            switch AVAudioSession.sharedInstance().recordPermission {
            case .granted:
                break
            case .denied:
                showError(message: "Microphone access denied. Please enable microphone access in Settings.")
            case .undetermined:
                AVAudioSession.sharedInstance().requestRecordPermission { [weak self] allowed in
                    DispatchQueue.main.async {
                        if !allowed {
                            self?.showError(message: "Microphone access is required for recording.")
                        }
                    }
                }
            @unknown default:
                break
            }
        }
    }
    
    func generateRandomPrompt() {
        if let languagePrompts = prompts[selectedLanguage], !languagePrompts.isEmpty {
            currentPrompt = languagePrompts.randomElement() ?? currentPrompt
        }
    }
    
    func startRecording() {
        // Set up audio session
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
            
            // Set up recording settings
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            // Create recording URL
            let recordingName = "recording_\(Date().timeIntervalSince1970).m4a"
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let outputURL = documentsURL.appendingPathComponent(recordingName)
            lastRecordingURL = outputURL
            
            // Initialize recorder
            audioRecorder = try AVAudioRecorder(url: outputURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            
        } catch {
            showError(message: "Failed to set up recording: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setActive(false)
    }
    
    func playLastRecording() {
        guard let recordingURL = lastRecordingURL else {
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: recordingURL)
            audioPlayer?.delegate = self
            audioPlayer?.play()
        } catch {
            showError(message: "Failed to play recording: \(error.localizedDescription)")
        }
    }
    
    func submitRecording() {
        guard let _ = lastRecordingURL else {
            return
        }
        
        isAnalyzing = true
        
        // Simulate AI analysis with sample data
        // In a real app, you would upload the recording to your API here
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            guard let self = self else { return }
            
            self.generateMockFeedback()
            self.isAnalyzing = false
            self.hasFeedback = true
        }
    }
    
    func resetFeedback() {
        hasFeedback = false
        transcript = ""
        wordsPerMinute = 0
        pronunciationFeedback = ""
        grammarFeedback = ""
        lastRecordingURL = nil
        generateRandomPrompt()
    }
    
    // MARK: - Private Methods
    
    private func showError(message: String) {
        errorMessage = message
        showError = true
    }
    
    private func generateMockFeedback() {
        // This is placeholder code to simulate AI feedback
        // In a real app, this would come from your backend
        
        switch selectedLanguage {
        case "English":
            transcript = "Hi, my name is Julia and I'm from New York. In my free time, I enjoy hiking in the mountains and reading science fiction books. I also like cooking Italian food, especially pasta dishes with different sauces."
            wordsPerMinute = Int.random(in: 90...120)
            pronunciationFeedback = "Good clarity overall. Pay attention to the 'th' sound in 'with'. Try to reduce rising intonation at the end of statements."
            grammarFeedback = "Good sentence structure. Consider using more varied transition phrases between topics. Your vocabulary is appropriate for conversation."
        case "Spanish":
            transcript = "Me llamo Carlos y vivo en Madrid. Me gusta mucho el cine y la música. Los fines de semana, me gusta salir con mis amigos a restaurantes y cafeterías."
            wordsPerMinute = Int.random(in: 80...110)
            pronunciationFeedback = "Buena pronunciación de las vocales. Presta atención a la 'r' rodada en 'restaurantes'. Intenta mantener un ritmo más consistente."
            grammarFeedback = "Buen uso de los verbos. Considera ampliar tu vocabulario con adjetivos más descriptivos. La estructura de las frases es correcta."
        case "French":
            transcript = "Je m'appelle Marie et j'habite à Paris. J'aime beaucoup la cuisine française et les promenades le long de la Seine. Le weekend, je visite souvent des musées."
            wordsPerMinute = Int.random(in: 85...115)
            pronunciationFeedback = "Bonne prononciation des voyelles nasales. Faites attention à la liaison entre les mots. Essayez de maintenir un rythme plus régulier."
            grammarFeedback = "Bon usage des temps verbaux. Considérez l'utilisation de connecteurs logiques pour lier vos idées. Votre vocabulaire est approprié pour la conversation."
        case "Japanese":
            transcript = "私の名前はケンです。東京に住んでいます。趣味は写真を撮ることと料理です。週末は友達と公園に行くことが多いです。"
            wordsPerMinute = Int.random(in: 70...100)
            pronunciationFeedback = "「り」の発音が自然です。長音の長さに気をつけてください。もう少しゆっくり話すと良いでしょう。"
            grammarFeedback = "助詞の使い方が正確です。もう少し複文を使うと良いでしょう。敬語と普通語の使い分けに気をつけてください。"
        case "Chinese":
            transcript = "我叫李明，我住在北京。我喜欢看电影和听音乐。周末的时候，我经常和朋友去公园散步。"
            wordsPerMinute = Int.random(in: 75...105)
            pronunciationFeedback = "声调掌握得不错，特别是第三声。注意「zh」和「ch」的发音区别。语速可以稍微放慢一点。"
            grammarFeedback = "句子结构正确。考虑使用更多的连词来连接句子。量词使用得当，但可以尝试使用更多样化的形容词。"
        case "German":
            transcript = "Ich heiße Thomas und ich wohne in Berlin. In meiner Freizeit gehe ich gerne ins Kino und höre Musik. Am Wochenende treffe ich mich oft mit Freunden."
            wordsPerMinute = Int.random(in: 85...115)
            pronunciationFeedback = "Gute Aussprache der Umlaute. Achten Sie auf die Betonung in längeren Wörtern. Versuchen Sie, den Rhythmus gleichmäßiger zu halten."
            grammarFeedback = "Guter Gebrauch der Wortstellung. Sie könnten mehr Konjunktionen verwenden, um Ihre Sätze zu verbinden. Ihr Wortschatz ist für ein Gespräch angemessen."
        default:
            transcript = "Hello, I am practicing my language skills with the Tong app."
            wordsPerMinute = Int.random(in: 90...120)
            pronunciationFeedback = "Your pronunciation is generally clear. Focus on maintaining consistent intonation throughout your sentences."
            grammarFeedback = "Your grammar structure is good. Consider using more connecting words to make your speech flow naturally."
        }
    }
}

// MARK: - AVAudioRecorderDelegate

extension PracticeViewModel: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            showError(message: "Recording failed. Please try again.")
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension PracticeViewModel: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        // Handle playback completion if needed
    }
} 