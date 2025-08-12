Title: Mobile Companion App for Agentic Orchestrator

Overview
- Build a minimal mobile app to monitor and interact with the orchestrator.
- Platforms: iOS SwiftUI.
- Backend: existing orchestrator API (FastAPI).

Goals
- Provide task visibility and live log streaming on mobile.
- Allow creating and starting simple tasks from the app.
- Keep implementation incremental and demo-friendly.

User Stories
- As a user, I can view a list of tasks with status so I can monitor progress.
- As a user, I can open a task detail screen to see steps and live logs so I can debug issues quickly.
- As a user, I can create a new task and start it so I can kick off work remotely.
- As a user, I can configure the server base URL so I can connect to different environments.

Requirements
- Task List:
  - GET /v1/tasks, render id, title, status with badges.
  - Pull-to-refresh support.
- Task Detail:
  - GET /v1/tasks/{id} to show steps and metadata.
  - Logs via WebSocket ws://host/v1/tasks/{id}/logs with graceful fallback to GET /v1/tasks/{id}/logs/tail.
- Create Task:
  - Form with title, description, repo_url; POST /v1/tasks then POST /v1/tasks/{id}/start.
- Settings:
  - Base URL (http://<LAN-IP>:8000) persisted locally.
  - Optional X-API-Key header (no-op for MVP).
- Errors/UX:
  - Surface 4xx/5xx errors as toasts.
  - Show loading/empty states.
  - Retry transport errors on logs.

Acceptance Criteria
- Task list loads within 2 seconds on local network.
- Live logs stream over WebSocket; if WS fails, tail polling updates within 2 seconds.
- Creating a task shows it on the list and navigates to detail.
- Base URL persists across app restarts.

Milestones
- M1: Task list + detail (REST) with tail polling.
- M2: WebSocket logs + create/start task flow.
- M3: Settings screen polish, error states.
- M4 (optional): Trigger PR review by PR number.

Technical Requirements
- Client:
  - SwiftUI, URLSession + URLSessionWebSocketTask.
- Backend integration:
  - CORS enabled for mobile dev origins.
  - No authentication required in MVP; support X-API-Key later.
- Logging:
  - Use server’s backlog-first WS behavior; handle 1008 close if task does not exist.
- CI:
  - Lint/typecheck on client; simple smoke tests.

Non-Goals (MVP)
- Push notifications.
- Complex auth flows.
- Deep diff viewer; rely on PR link.
