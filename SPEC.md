I've created a comprehensive project specification document for the Mobile Companion App for Agentic Orchestrator. The SPEC.md includes:

## Key Sections Covered:

**Project Overview** - iOS SwiftUI app for monitoring and basic interaction with orchestrator

**Goals & Objectives** - Mobile visibility, remote task creation, live monitoring, cross-environment support

**User Stories** - 7 detailed user stories covering core functionality from task viewing to configuration

**Requirements** - 22 functional requirements (FR-001 to FR-022) and 12 non-functional requirements (NFR-001 to NFR-012) covering:
- Task list management
- Task detail views with live logs
- Task creation workflow
- Settings management
- Error handling and UX
- Performance, reliability, and usability standards

**Technical Architecture** - SwiftUI stack, URLSession networking, WebSocket streaming, API endpoints, and data models

**Success Criteria** - Detailed acceptance criteria for each milestone and overall project success

**Constraints & Assumptions** - Technical and business constraints, plus key assumptions

**Out of Scope** - Explicitly excluded features like push notifications, complex auth, Android support

**Development Milestones** - 4 phases with 2-3 week durations each:
- M1: Core REST functionality with polling
- M2: WebSocket streaming + task creation  
- M3: Settings and error handling polish
- M4: Optional advanced features

**Quality Assurance** - Testing strategy and code quality standards

The specification captures all requirements from the inception discussion and structures them into actionable, testable requirements ready for implementation.
