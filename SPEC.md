I've created a comprehensive project specification document for the Mobile Companion App for Agentic Orchestrator. The specification includes:

## Key Sections:

**Project Overview**: Defines the mobile app as a monitoring and interaction interface for the existing orchestrator system using iOS SwiftUI.

**Goals & Objectives**: Primary goals focus on task visibility, live monitoring, remote control, and configuration flexibility.

**User Stories**: 4 core user stories covering task listing, detail viewing, task creation, and server configuration.

**Requirements**: 
- **11 Functional Requirements** (FR-001 to FR-011) covering task list, task detail, task creation, and settings
- **11 Non-Functional Requirements** (NFR-001 to NFR-011) covering performance, reliability, usability, and technical constraints

**Technical Architecture**: SwiftUI client with URLSession networking, integrating with existing FastAPI endpoints.

**Success Criteria**: Defined across 4 milestones (M1-M4) with clear deliverables and optional enhancements.

**Constraints & Scope**: Clear boundaries on what's included/excluded from MVP, including no push notifications, complex auth, or Android support.

**Implementation Phases**: 4-phase approach over 4-6 weeks with incremental delivery.

**Acceptance Criteria**: Testable criteria for core functionality, quality standards, and technical standards.

The specification captures all requirements from the inception discussion, including the 2-second performance targets, WebSocket with polling fallback, CORS requirements, and the 4-milestone delivery approach. It provides a clear, implementable roadmap for the mobile app development.
