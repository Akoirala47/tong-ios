import SwiftUI
import AVFoundation
import Foundation

struct PracticeView: View {
    @StateObject private var viewModel = PracticeViewModel()
    @State private var showingLanguageSelector = false
    @State private var isRecording = false
    @State private var recordingDuration: Double = 0
    @State private var timer: Timer?
    
    // Animation properties
    @State private var waveformScale: CGFloat = 1.0
    @State private var waveformOpacity: Double = 0.5
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                
                promptSection
                
                recordingSection
                
                if viewModel.isAnalyzing {
                    analyzingSection
                } else if viewModel.hasFeedback {
                    feedbackSection
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Practice")
        .background(Color(.systemGroupedBackground))
        .onAppear {
            viewModel.checkMicrophonePermission()
        }
        .sheet(isPresented: $showingLanguageSelector) {
            languageSelectorSheet
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - UI Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Improve Your Pronunciation")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Record yourself speaking and get instant AI feedback")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var promptSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Speaking Prompt")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Button(action: {
                        showingLanguageSelector = true
                    }) {
                        HStack {
                            Text(viewModel.selectedLanguage)
                                .foregroundColor(.primary)
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    viewModel.generateRandomPrompt()
                }) {
                    Label("New Prompt", systemImage: "arrow.2.squarepath")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(hex: "00BFFF").opacity(0.2))
                        .foregroundColor(Color(hex: "00BFFF"))
                        .cornerRadius(8)
                }
            }
            
            Text(viewModel.currentPrompt)
                .font(.system(size: 18))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(12)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var recordingSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Waveform background
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(Color(hex: "FF9F1C").opacity(0.2), lineWidth: 3)
                        .frame(width: 120 + CGFloat(index * 40), height: 120 + CGFloat(index * 40))
                        .scaleEffect(isRecording ? waveformScale : 1.0)
                        .opacity(isRecording ? waveformOpacity : 0.2)
                }
                
                // Record button
                Button(action: {
                    if isRecording {
                        stopRecording()
                    } else {
                        startRecording()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(isRecording ? Color(hex: "FF9F1C") : Color(hex: "00BFFF"))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }
                }
                .disabled(viewModel.isAnalyzing)
            }
            .padding(.vertical, 20)
            
            if isRecording {
                Text(timeString(from: recordingDuration))
                    .font(.system(.title, design: .monospaced))
                    .foregroundColor(Color(hex: "FF9F1C"))
            } else {
                Text("Tap the microphone to start recording")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if !isRecording && !viewModel.isAnalyzing && viewModel.lastRecordingURL != nil {
                HStack(spacing: 20) {
                    Button(action: {
                        viewModel.playLastRecording()
                    }) {
                        Label("Play", systemImage: "play.fill")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(hex: "00BFFF"))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Button(action: {
                        viewModel.submitRecording()
                    }) {
                        Label("Submit for Analysis", systemImage: "arrow.up.circle.fill")
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(hex: "00BFFF"))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var analyzingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .padding()
            
            Text("Analyzing your pronunciation...")
                .font(.headline)
            
            Text("Our AI is listening to your recording and preparing feedback")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private var feedbackSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI Feedback")
                .font(.headline)
                .padding(.bottom, 4)
            
            Group {
                feedbackItem(title: "Transcript", content: viewModel.transcript, icon: "text.bubble.fill")
                
                feedbackItem(title: "Words per Minute", content: "\(viewModel.wordsPerMinute) WPM", icon: "speedometer")
                
                feedbackItem(title: "Pronunciation", content: viewModel.pronunciationFeedback, icon: "waveform.path")
                
                feedbackItem(title: "Grammar & Fluency", content: viewModel.grammarFeedback, icon: "text.book.closed.fill")
            }
            
            HStack {
                Spacer()
                
                Button(action: {
                    viewModel.resetFeedback()
                }) {
                    Text("Try Again")
                        .font(.headline)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color(hex: "00BFFF"))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    private func feedbackItem(title: String, content: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color(hex: "00BFFF"))
                Text(title)
                    .font(.headline)
            }
            
            Text(content)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(8)
        }
        .padding(.bottom, 8)
    }
    
    private var languageSelectorSheet: some View {
        NavigationView {
            List {
                ForEach(viewModel.availableLanguages, id: \.self) { language in
                    Button(action: {
                        viewModel.selectedLanguage = language
                        showingLanguageSelector = false
                        viewModel.generateRandomPrompt()
                    }) {
                        HStack {
                            Text(language)
                            Spacer()
                            if language == viewModel.selectedLanguage {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color(hex: "00BFFF"))
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationBarTitle("Select Language", displayMode: .inline)
            .navigationBarItems(trailing: Button("Done") {
                showingLanguageSelector = false
            })
        }
    }
    
    // MARK: - Helper Functions
    
    private func startRecording() {
        viewModel.startRecording()
        isRecording = true
        recordingDuration = 0
        
        // Setup animation
        withAnimation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
            waveformScale = 1.1
            waveformOpacity = 0.8
        }
        
        // Setup timer
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            recordingDuration += 0.1
            
            // Automatically stop after 30 seconds
            if recordingDuration >= 30.0 {
                stopRecording()
            }
        }
    }
    
    private func stopRecording() {
        viewModel.stopRecording()
        isRecording = false
        timer?.invalidate()
        timer = nil
        
        // Reset animation
        withAnimation {
            waveformScale = 1.0
            waveformOpacity = 0.5
        }
    }
    
    private func timeString(from duration: Double) -> String {
        let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
        let tenths = Int((duration * 10).truncatingRemainder(dividingBy: 10))
        return String(format: "%02d.%01d", seconds, tenths)
    }
}

struct PracticeView_Previews: PreviewProvider {
    static var previews: some View {
        PracticeView()
    }
} 