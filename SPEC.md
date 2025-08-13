I've created a comprehensive project specification document that captures all the requirements from the inception discussion. The SPEC.md includes:

**Key Sections:**
- **Project Overview** - Mobile iOS app for orchestrator monitoring
- **Goals & Objectives** - Task visibility, live monitoring, remote creation
- **User Stories** - 7 detailed user scenarios
- **Requirements** - 15 functional and non-functional requirements with clear REQ-IDs
- **Technical Architecture** - SwiftUI, URLSession, WebSocket integration
- **Success Criteria** - 4 milestones with specific acceptance criteria
- **Constraints & Assumptions** - Platform limits, backend dependencies
- **Out of Scope** - Clear MVP boundaries (no push notifications, complex auth, etc.)
- **Implementation Phases** - 4-week development timeline

**Key Requirements Captured:**
- Task list with GET `/v1/tasks` and pull-to-refresh
- Task detail with WebSocket logs and polling fallback
- Task creation with POST endpoints
- Settings with URL persistence
- Comprehensive error handling and UX states
- 2-second performance targets

The specification is actionable, testable, and maintains the incremental/demo-friendly approach discussed in the inception issue.
