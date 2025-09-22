# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AIc is an AI companion app for teenagers (ages 9-18) built as a monorepo. The system consists of a Flutter mobile app, NestJS backend API with WebSocket support, shared packages, and Docker infrastructure for local development.

## Development Commands

### Environment Setup
```bash
# Start local infrastructure (PostgreSQL, Redis, Adminer, Redis Commander)
npm run infra:up

# Stop infrastructure
npm run infra:down

# Database setup (run after infra:up)
npm run db:migrate    # Apply Prisma migrations
npm run db:seed       # Seed with test data
```

### Development
```bash
# Start both API and mobile app in parallel
npm run dev

# Individual services
npm run dev:api       # Start NestJS API server on :3000
npm run dev:mobile    # Start Flutter app (requires emulator/device)

# Build all components
npm run build         # Build packages + API
npm run build:packages # Build shared packages only
npm run build:api     # Build API only
```

### Testing & Quality
```bash
npm test              # Run all tests (API + mobile)
npm run test:api      # API tests only
npm run test:mobile   # Flutter tests only

npm run lint          # Lint all code
npm run lint:api      # ESLint + Prettier for API
npm run lint:mobile   # Flutter analyze

npm run clean         # Clean all build artifacts
```

### API-Specific Commands
```bash
cd apps/api

# Prisma database management
npm run prisma:gen      # Generate Prisma client
npm run prisma:migrate  # Run dev migrations
npm run prisma:deploy   # Deploy migrations (production)

# Development
npm run dev            # Start with hot reload
npm test               # Jest unit tests
npm run test:e2e       # End-to-end tests
npm run seed           # Populate database with test data
```

### Mobile-Specific Commands
```bash
cd apps/mobile

flutter pub get        # Install dependencies
flutter run           # Run on connected device/emulator
flutter run -d chrome # Run web version
flutter test          # Run unit tests
flutter analyze       # Static analysis
flutter clean         # Clean build cache
```

## Architecture

### Monorepo Structure
- **apps/mobile/** - Flutter client app with feature-based architecture
- **apps/api/** - NestJS backend with modular structure
- **packages/common/** - Shared TypeScript types and utilities
- **packages/safety/** - Safety rules and SOS templates
- **infra/** - Docker Compose for local development

### Key Technologies
- **Backend**: NestJS, Prisma ORM, PostgreSQL, Redis, WebSocket (Socket.io)
- **Mobile**: Flutter 3.22+, Riverpod (state management), Go Router (navigation)
- **Shared**: TypeScript, Docker, Node.js 18+

### Database Schema (Prisma)
Core models: User, Profile, ChatSession, ChatMessage, Article, SosContact, Purchase, Notification, SafetyLog

Age groups: 9-12, 13-15, 16-18
Supported locales: cs-CZ, de-DE, en-US

### API Architecture
- Modular NestJS structure with feature modules: auth, chat, users, content, sos, subscriptions
- WebSocket gateway for real-time chat (`/chat` endpoint)
- Swagger documentation at `http://localhost:3000/api`
- Safety logging and content filtering throughout
- RevenueCat integration for subscriptions

### Mobile Architecture
- Feature-based folder structure under `lib/features/`
- Riverpod for state management
- Services layer for API communication and local storage
- Localization support with `intl` package
- Integrations: Firebase messaging, RevenueCat, Amplitude analytics

## Safety & Content Guidelines

This app serves teenagers and implements multi-layered safety:
- Crisis content detection and escalation
- Age-appropriate content filtering
- SOS system with emergency contacts by country/locale
- All interactions logged for safety analysis

When working on features:
- Consider age group appropriateness (9-12, 13-15, 16-18)
- Implement proper safety logging for user interactions
- Test crisis trigger detection for chat features
- Ensure SOS resources are properly localized

## Development Workflow

1. **Database Changes**: Update `apps/api/prisma/schema.prisma`, run migrations
2. **API Changes**: Follow NestJS module pattern, update Swagger docs
3. **Mobile Changes**: Follow Flutter/Dart conventions, update localization if needed
4. **Shared Types**: Add to `packages/common/src/`, rebuild packages

## Local Development URLs

- API Server: http://localhost:3000
- Swagger UI: http://localhost:3000/api
- PostgreSQL: localhost:5432 (user: postgres, password: postgres, db: aic)
- Redis: localhost:6379
- Adminer (DB UI): http://localhost:8080
- Redis Commander: http://localhost:8081

## Important Notes

- Always run `npm run infra:up` before starting development
- The API uses Prisma - run `npm run db:migrate` after schema changes
- Mobile app requires Flutter 3.22+ and connected device/emulator
- All safety-related code should include proper logging and escalation paths
- When adding new API endpoints, update Swagger documentation
- Follow conventional commits for commit messages