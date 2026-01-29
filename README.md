# Bodii

Korean health and fitness tracking app with AI-powered diet insights.

## Setup

### API Keys Required

Bodii integrates with external APIs. You need to configure API keys before running the app:

1. **Gemini API** (for AI diet comments + photo food recognition): See [Gemini API Setup Guide](./docs/GEMINI_API_SETUP.md)
2. **KFDA API** (Korean food database): Optional for development (uses DEMO_KEY)
3. **USDA API** (US food database): Optional for development (uses DEMO_KEY)

**Quick Start**:
```bash
# 1. Get your Gemini API key
open https://makersuite.google.com/app/apikey

# 2. Add to Info.plist
# GEMINI_API_KEY = "your-key-here"

# 3. Build and run
xcodebuild ...
```

See detailed setup instructions: [docs/GEMINI_API_SETUP.md](./docs/GEMINI_API_SETUP.md)

## Features

- 📊 Daily diet tracking with macro nutrients
- 📸 AI photo food recognition (Gemini Multimodal) - take a photo, get instant nutrition analysis
- 🤖 AI-powered diet comments, daily diet score, and recommendations (Gemini API)
- 🍚 Korean food database integration (KFDA)
- 🥗 US food database integration (USDA)
- 💪 Exercise tracking with calorie burn calculation
- 😴 Sleep tracking
- 🎯 Personalized health goals (weight loss/gain/maintain)
- 📈 TDEE-based calorie recommendations
- ⌚ Apple HealthKit integration

## Architecture

This app follows Clean Architecture principles:
- **Domain Layer**: Entities, Use Cases, Protocols
- **Data Layer**: Repositories, DTOs, Data Sources
- **Presentation Layer**: ViewModels, Views (SwiftUI)
- **Infrastructure Layer**: Network, API Configuration

## Development

### Prerequisites

- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+
- Gemini API key (required for AI features)

### Building

1. Clone the repository
2. Configure API keys (see Setup section above)
3. Open `Bodii.xcodeproj` in Xcode
4. Build and run (Cmd+R)

## Documentation

- [Gemini API Setup](./docs/GEMINI_API_SETUP.md) - Configure AI features (diet comments + photo recognition)
- [PRD](./docs/01_PRD.md) - Product requirements
- [Feature Spec](./docs/02_FEATURE_SPEC.md) - Feature specifications
- [ERD](./docs/04_ERD.md) - Data model
- [Tasks](./docs/05_TASKS.md) - Implementation tasks
- [Algorithm](./docs/06_ALGORITHM.md) - BMR/TDEE calculations
- [Edge Cases](./docs/08_EDGE_CASES.md) - Exception handling

## License

Copyright © 2026 Bodii. All rights reserved.
