I've created a comprehensive project specification document based on the inception issue and discussion. The SPEC.md includes:

**Key Sections:**
- **Project Overview** - Clear summary of the mobile companion app goals
- **Goals and Objectives** - Primary goals with success metrics  
- **User Stories** - Four core user stories from the inception issue
- **Requirements** - 20 functional requirements (FR-001 to FR-020) and 9 non-functional requirements (NFR-001 to NFR-009)
- **Technical Architecture** - SwiftUI stack, API endpoints, WebSocket behavior
- **Success Criteria** - 4 milestone-based criteria with checkboxes
- **Constraints and Assumptions** - Technical and project constraints
- **Out of Scope** - Explicit MVP exclusions (push notifications, complex auth, etc.)
- **Implementation Phases** - 4-phase delivery plan matching the milestones
- **Quality Assurance** - Testing strategy and code quality requirements
- **Risk Mitigation** - Technical and project risk handling

**Key Features Captured:**
- Task list with status badges and pull-to-refresh
- Task detail with live WebSocket logs and polling fallback  
- Task creation form with title/description/repo_url
- Settings screen for base URL configuration
- Comprehensive error handling and UX states
- Performance requirements (2-second load times)

The specification is implementable, testable, and provides clear acceptance criteria for each milestone while maintaining focus on the MVP scope.
