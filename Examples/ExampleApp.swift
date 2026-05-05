import SwiftUI
import AutoIQ

/// Example app showing how to integrate Auto IQ into an iOS app.
@main
struct AutoIQExampleApp: App {
    @StateObject private var autoIQ = AutoIQService(
        apiKey: "sk-ant-...",  // Replace with actual API key
        userId: "example_user_123"
    )

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(autoIQ)
        }
    }
}

// MARK: - Main Content View

struct ContentView: View {
    @EnvironmentObject var autoIQ: AutoIQService
    @State private var selectedTab: Tab = .browse

    enum Tab {
        case browse, chat, profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // Browse Cars
            BrowseView()
                .tabItem {
                    Label("Browse", systemImage: "car")
                }
                .tag(Tab.browse)

            // Chat
            ChatView()
                .tabItem {
                    Label("Auto IQ", systemImage: "bubble.right")
                }
                .tag(Tab.chat)

            // Profile
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle")
                }
                .tag(Tab.profile)
        }
        .overlay(alignment: .top) {
            if let flag = autoIQ.activeRiskFlags.first {
                RiskFlagBanner(flag: flag)
                    .transition(.move(edge: .top))
            }
        }
    }
}

// MARK: - Browse View

struct BrowseView: View {
    @EnvironmentObject var autoIQ: AutoIQService

    var body: some View {
        NavigationStack {
            VStack {
                Text("Vehículos Disponibles")
                    .font(.title2)
                    .fontWeight(.bold)

                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(0..<5, id: \.self) { index in
                            CarCardView(
                                car: .mockCar(id: "car_\(index)")
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("AutomatchIA")
        }
    }
}

// MARK: - Car Card

struct CarCardView: View {
    let car: MockCar
    @EnvironmentObject var autoIQ: AutoIQService
    @State private var cardAppearTime = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 200)
                .overlay {
                    Text("🚗 \(car.marca) \(car.modelo)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }

            // Details
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(car.año) • \(car.kilometraje) km")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("$\(Int(car.precio).formattedCOP)")
                        .font(.headline)
                        .fontWeight(.bold)
                }

                Text(car.tipo)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }

            // Actions
            HStack(spacing: 12) {
                Button(action: { recordSwipe(.swipeLeft) }) {
                    Label("No", systemImage: "xmark.circle.fill")
                        .foregroundColor(.red)
                }
                Spacer()
                Button(action: { recordSwipe(.swipeRight) }) {
                    Label("Sí", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .font(.headline)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .onAppear {
            cardAppearTime = Date()
        }
    }

    private func recordSwipe(_ direction: SwipeDirection) {
        let dwell = Date().timeIntervalSince(cardAppearTime)
        let snapshot = BehavioralSignal.CarSnapshot(
            id: car.id,
            marca: car.marca,
            modelo: car.modelo,
            año: car.año,
            precio: car.precio,
            tipo: car.tipo,
            combustible: car.combustible,
            transmision: car.transmision,
            nivelLujo: car.nivelLujo
        )

        let signalType: BehavioralSignal.SignalType
        switch direction {
        case .right:
            signalType = .swipeRight
        case .left:
            signalType = dwell < 1.5 ? .swipeLeftFast : .swipeLeftSlow
        case .up:
            signalType = .swipeUp
        }

        autoIQ.recordSignal(BehavioralSignal(
            signalType: signalType,
            sessionId: UUID().uuidString,
            carSnapshot: snapshot,
            dwellDurationSeconds: dwell
        ))
    }
}

enum SwipeDirection {
    case left, right, up
}

// MARK: - Chat View

struct ChatView: View {
    @EnvironmentObject var autoIQ: AutoIQService
    @State private var userMessage = ""
    @State private var messages: [ChatMessage] = []

    struct ChatMessage: Identifiable {
        let id = UUID()
        let role: String  // "user" or "assistant"
        let content: String
    }

    var body: some View {
        VStack {
            // Messages
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(messages) { msg in
                        HStack {
                            if msg.role == "user" {
                                Spacer()
                            }
                            Text(msg.content)
                                .padding(12)
                                .background(
                                    msg.role == "user" ?
                                    Color.blue : Color.gray.opacity(0.2)
                                )
                                .foregroundColor(
                                    msg.role == "user" ? .white : .primary
                                )
                                .cornerRadius(12)
                            if msg.role == "assistant" {
                                Spacer()
                            }
                        }
                    }
                    if !autoIQ.streamingText.isEmpty {
                        HStack {
                            Text(autoIQ.streamingText)
                                .padding(12)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
                            Spacer()
                        }
                    }
                }
                .padding()
            }

            // Input
            HStack {
                TextField("Pregunta a Auto IQ...", text: $userMessage)
                    .textFieldStyle(.roundedBorder)
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.blue)
                }
                .disabled(userMessage.isEmpty || autoIQ.isStreaming)
            }
            .padding()
        }
        .navigationTitle("Auto IQ Chat")
    }

    private func sendMessage() {
        let msg = userMessage
        userMessage = ""
        messages.append(ChatMessage(role: "user", content: msg))

        Task {
            await autoIQ.chat(msg)
            messages.append(ChatMessage(role: "assistant", content: autoIQ.streamingText))
        }
    }
}

// MARK: - Profile View

struct ProfileView: View {
    @EnvironmentObject var autoIQ: AutoIQService

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                if let profile = autoIQ.currentProfile {
                    // Confidence
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Profile Confidence")
                            .font(.headline)
                        ProgressView(value: profile.overallConfidence)
                        Text("\(Int(profile.overallConfidence * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Decision Stage
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Decision Stage")
                            .font(.headline)
                        Text(profile.decisionStage.rawValue.capitalized)
                            .font(.body)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Archetypes
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Buyer Archetypes")
                            .font(.headline)
                        ForEach(profile.archetypes) { archetype in
                            HStack {
                                Text(archetype.displayName)
                                Spacer()
                                Text("\(Int(archetype.confidence * 100))%")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    Spacer()
                } else {
                    Text("Loading profile...")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .navigationTitle("Your Profile")
        }
    }
}

// MARK: - Risk Flag Banner

struct RiskFlagBanner: View {
    let flag: RiskFlag
    @EnvironmentObject var autoIQ: AutoIQService

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text(flag.message)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: { autoIQ.dismissRiskFlag(flag) }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
            Text(flag.recommendedAction)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .padding()
    }
}

// MARK: - Mock Data

struct MockCar {
    let id: String
    let marca: String
    let modelo: String
    let año: Int
    let precio: Double
    let tipo: String
    let combustible: String
    let transmision: String
    let nivelLujo: String
    let kilometraje: Int

    static func mockCar(id: String) -> MockCar {
        let marcas = ["Toyota", "Mazda", "Hyundai", "Kia", "Chevrolet"]
        let modelos = ["Corolla", "CX-5", "Elantra", "Sportage", "Cruze"]
        let tipos = ["sedan", "suv", "pickup", "hatchback"]
        let combustibles = ["gasolina", "diesel", "híbrido"]

        return MockCar(
            id: id,
            marca: marcas.randomElement() ?? "Toyota",
            modelo: modelos.randomElement() ?? "Corolla",
            año: Int.random(in: 2018...2024),
            precio: Double.random(in: 20_000_000...80_000_000),
            tipo: tipos.randomElement() ?? "sedan",
            combustible: combustibles.randomElement() ?? "gasolina",
            transmision: Bool.random() ? "automática" : "manual",
            nivelLujo: Bool.random() ? "estándar" : "premium",
            kilometraje: Int.random(in: 10_000...150_000)
        )
    }
}

#Preview {
    ContentView()
        .environmentObject(MockAutoIQService())
}
