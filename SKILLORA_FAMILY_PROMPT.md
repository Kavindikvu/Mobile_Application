## App Naming

- App Name: Skillora Family
- Project Name: skillora-family-mobile

---

## Prompt for Cursor to Generate the Student/Parent App UX and UI

You are building a Flutter mobile application named "Skillora Family" (project: "skillora-family-mobile"). It is the companion app to the existing teacher/organiser-facing Skillora app. Both apps share the same backend APIs and data models, but this app targets students and parents with tailored user journeys, IA, and UX. Think of it like a driver vs. passenger app pairing, where the teacher app is for supply/management and this app is for discovery, participation, and monitoring.

### Core Principles
- Align visual identity, components, spacing, typography, color tokens, and micro-interactions with the existing Skillora app design language while adapting tone and IA for families.
- Prioritize clarity, trust, and simplicity for parents; engagement and motivation for students.
- Design for future extensibility: the app will gain more modules over time without re-architecture.
- Ensure excellent accessibility (minimum WCAG AA) and responsive behavior from small phones to large phones.
- Support light and dark themes consistent with the teacher app brand.
- Optimize perceived performance: skeletons, shimmer where appropriate, optimistic updates, and meaningful loading/empty/error states.
- Internationalization-ready and RTL-ready. All user-facing strings must be sourced via localization.

### Users and Roles
- Roles: Parent, Student. A parent may manage multiple children; a student has their own profile.
- Session model: Unified auth compatible with existing backend; reuse token/session logic. Support login via email/password and provider sign-ins (if available in the backend). Handle role switching fluidly in-app.

### Must-Have Feature Modules (MVP)
1) Class Discovery & Teacher Search
   - Browse/search classes by subject, teacher, location/online, time, level, price, and rating.
   - Class details: schedule, capacity, teacher profile, syllabus/outline, reviews, media.
   - Save/bookmark, subscribe/follow classes and teachers.

2) Reviews & Ratings
   - Read and publish class/teacher feedback (respecting role-based permissions and moderation).
   - Capture structured rating dimensions (clarity, engagement, materials, pacing) and free-text.

3) Assignments
   - View assigned tasks, due dates, attachments, and instructions.
   - Submit assignments with file uploads, notes, and re-submissions (if allowed).
   - Show submission status, grades, and teacher feedback.

4) Attendance & Parent Notifications
   - Parents receive real-time attendance updates for each child.
   - Daily/weekly summaries and alerts for absences or late marks.

5) Performance & Activity Monitoring
   - Progress snapshots: recent grades, assignment completion rate, attendance streaks.
   - Trends over time with simple charts; actionable insights and nudges.

6) Marketplace (Used Books & School Items)
   - Browse, search, and filter listings; item detail pages with images, condition, price.
   - Post items for sale (role restrictions configurable), chat/contact seller, manage listings.

7) Notifications & Messaging
   - Central inbox for system notifications and messages from subscribed classes/teachers.
   - Grouped by class/teacher; badge counts, read/unread states.

8) Profile & Achievements
   - Maintain profiles for parent and student(s): avatar, bio, grade/level, preferences.
   - Upload achievement artifacts: certificates, badges, results. Curated timeline view.

### Information Architecture & Navigation
- Bottom navigation with up to 5 primary tabs for MVP:
  1. Discover
  2. Assignments
  3. Home (Overview)
  4. Messages
  5. Profile
- Within Profile, allow role switching (Parent profile, switch child profile) and account settings.
- Deep-linkable routes and state restoration. Use Navigator 2.0 patterns consistent with the teacher app.

### UI & Design System Requirements
- Reuse or mirror the existing Skillora component library where possible:
  - Buttons, icon buttons, segmented controls, inputs, pickers, cards, chips, tabs, banners, toasts/snackbars, sheets, dialogs, loaders, skeletons.
  - Typography scale and color tokens must mirror the teacher app’s foundation with adapted states (hover, pressed, disabled), elevation, and shadows.
- Provide variants for student-friendly visuals (more playful accents, motivational microcopy) vs parent-friendly views (more dashboards, summaries, clarity).
- Include coherent empty, loading, and error states for each module, with visuals and calls to action.
- Asset strategy: reuse brand assets (logos) and iconography to ensure family resemblance.

### Interaction & Microcopy Guidelines
- Keep flows short with progressive disclosure; avoid cognitive overload.
- Microcopy tone: encouraging and helpful for students; clear and reliable for parents.
- Confirmations and undo patterns where destructive or high-friction actions occur.
- Use subtle haptics and animations that match the teacher app’s motion curve.

### Technical & Integration Guidelines
- Flutter app, same package setup conventions as the existing app. Follow the project’s clean architecture and layering approach.
- Networking: use the same backend endpoints and auth tokens. Respect existing error shapes and pagination standards.
- State management: align with the teacher app’s chosen approach (e.g., Provider/Bloc/Riverpod) for consistency.
- Storage: follow existing secure storage and caching patterns. Support offline-friendly read views for key modules (Assignments, Messages, Discover search history).
- Push notifications: mirror existing Firebase or chosen provider configuration.
- Analytics: events aligned to the teacher app taxonomy with role and child context.

### Deliverables for the Initial Implementation
1) Project Scaffolding
   - Folder structure matching the teacher app (core, features, etc.).
   - Theming setup with light/dark and shared token file(s).
   - Localization scaffold with example strings and extraction setup.

2) Navigation & Shell
   - Implement bottom nav with 5 tabs and preserved state per tab.
   - Route map with deep-link support and typed route arguments.

3) Screens (High-Fidelity)
   - Home (Overview): role-aware dashboard (parent/students), recent activity, quick actions.
   - Discover: class list, filters, detail page, save/subscribe.
   - Assignments: list, detail, submission flow with upload UI.
   - Messages: inbox list, thread view with composer.
   - Profile: parent/student profile(s), achievements, role/child switcher, settings entry.

4) Components & States
   - Shared widgets: card lists, rating display/editor, attendance chips, trend mini-charts, marketplace listing cards.
   - Empty/loading/error states with appropriate visuals and guidance.

5) Integration Stubs (API layer)
   - Auth/session integration (shared backend contract).
   - Stubbed repositories/services for classes, assignments, attendance, messaging, marketplace, profiles.
   - Mock data providers to run the app end-to-end without live backend.

6) Quality & Accessibility
   - AA contrast, scalable fonts, larger touch targets.
   - Screen reader labels and traversal order.
   - Basic widget tests for routing and core components.

### Acceptance Criteria
- The app builds and runs with mock data, showing all MVP tabs and flows.
- Visual language clearly matches the Skillora brand while feeling tailored to families.
- Role switching works without app restarts; parent can switch between children.
- All screens include empty/loading/error handling and look refined in both themes.
- Navigation is deep-linkable and preserves state per tab.
- Localization ready with a few example keys; RTL rendering shows no layout issues.

### Stretch Goals (Optional if time allows)
- Downloadable offline packets for assignments.
- In-app marketplace chat with safe-guarding.
- Calendar integration for due dates and class schedules.
- Achievement badge system with shareable cards.

### Output Expectations
- Generate the full Flutter scaffold, theming, and screens listed above.
- Provide a short README describing how the app aligns with the existing teacher app, how to switch roles, and how to plug in the real backend.
- Include a design tokens file mirroring the teacher app with any added tokens documented.

Build a delightful, trustworthy, and cohesive companion experience that parents and students love, while staying in lock-step with the teacher/organiser Skillora app’s design DNA.


