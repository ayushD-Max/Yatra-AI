# YatraAI - Intelligent Trip Planner

YatraAI is a Flutter application that helps users discover places, plan personalized trips, and seamlessly modify itineraries using natural language (AI-driven). 

## 🚀 Setup Instructions

1. **Clone the repository:**
   ```bash
   git clone https://github.com/ayushD-Max/Yatra-AI.git
   cd Yatra-AI
   ```

2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Environment Setup:**
   Create a `.env` file in the root directory and add your Gemini API Key:
   ```env
   GEMINI_API_KEY=your_api_key_here
   ```
   *(Note: The app has a robust local offline fallback if the API key is missing or the API is overloaded).*

4. **Run the App:**
   ```bash
   flutter run
   ```

## 🏗️ Architecture

The app follows a **Feature-First (Domain-Driven) Architecture**, ensuring separation of concerns and scalability:
- **`lib/core/`**: Contains shared models, theme definitions, network logic, reusable widgets (like `GlassContainer`, `AppSearchBar`), and routing (`AppRouter`).
- **`lib/features/`**: Divided into domain-specific features (`home`, `explore`, `trip_planning`, `itinerary`, `profile`, `favorites`). Each feature contains its own `presentation` (screens, widgets) and `cubit` (state management).

## 🧩 State-Management Approach

**BLoC / Cubit (flutter_bloc)**
- **Why Cubit?**: Cubit is used over standard BLoC to reduce boilerplate while maintaining predictable state transitions. 
- Complex state logic, like generating and modifying itineraries (`ItineraryCubit`), is separated from the UI.
- `BlocBuilder` and `BlocConsumer` are used to render loading states (like skeleton loaders) and trigger side effects (like the AI explanation bottom sheet).

## 💾 Data & API Approach

1. **Natural Language Parsing (Gemini API & Local Fallback)**:
   - The app uses the **Gemini 1.5 Flash API** (`GeminiService`) to parse natural language queries (e.g., *"I have 1 day for Rajgad Fort with ₹1000 budget"*) into structured JSON `TripModification` objects.
   - **Offline/Rate-Limit Fallback**: If Gemini fails or rate limits, the app falls back to a highly robust regex-based local parser (`TripModificationParser`) that extracts duration, budget, constraints, and specific known places (including typo correction like "rajadad" -> "Rajgad Fort").

2. **Mock Data Source**:
   - Place data is loaded locally via `MockPlaceRepository` using JSON files (`assets/mocks/pune.json`, etc.). 
   - Images are sourced from Unsplash/Pexels for a realistic look and feel.

3. **Local Storage**:
   - `SharedPreferences` is used to persist the active itinerary, user preferences, and profile data across app restarts.

## 🛠️ Key Technical Decisions

- **Dynamic Itinerary Generation Algorithm**: `ItineraryGenerator` dynamically slots places into Morning, Lunch, Afternoon, and Evening based on location proximity (calculating distance between activities to optimize travel), budget constraints, and user preferences (indoor/outdoor, categories).
- **Conversational UI Cold-Start**: Instead of just modifying an existing trip, the chat bar on the itinerary screen can generate a brand-new trip entirely from a single text prompt.
- **Declarative Navigation**: Built on `go_router` for deep-linking support and clean declarative navigation.
- **UI/UX**: Extensive use of Glassmorphism (blur effects) and smooth micro-animations to give a premium, modern feel.

## ✨ Additional Features Implemented

- **Dual Viewing Modes**: Users can switch between a standard chronological **Timeline** view and an immersive **Storymode** view for their itinerary.
- **Smart Focus Navigation**: Tapping the search bar on the Home screen seamlessly routes to the Explore screen and automatically focuses the keyboard.
- **Keyboard-Aware Layout**: The AI chat input floats dynamically above the keyboard when typing, ensuring a smooth conversational flow.

## ⚠️ Known Limitations

- **Mock Data Scope**: The current database is limited to select cities (primarily Pune and generic mock data).
- **Distance Calculation**: The `ItineraryGenerator` uses simple Euclidean distance mapping rather than a real-world mapping API (like Google Maps Distance Matrix) due to the lack of an active Maps API key.
- **Gemini API Limits**: Free-tier Gemini API can face 429 Overload errors during heavy use, which is why the local fallback parser was heavily invested in.
