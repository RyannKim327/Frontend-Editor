# Frontend Editor

## 1. Project Overview

**Project Name:** Kimmy Dev Server  
**Application ID:** `org.mpop.frontend_editor`  
**Platform:** Android  
**Framework:** Flutter  
**Primary Language:** Dart

Kimmy Dev Server is a mobile frontend development environment designed to run and preview frontend projects directly on Android devices.

The application is inspired by VS Code Live Server, but aims to provide more than a basic static file server.

Users should be able to:
- Create and manage frontend projects.
- Import existing frontend projects.
- Browse project files.
- Edit source code.
- Start and stop local development servers.
- Preview websites using an embedded WebView.
- Automatically refresh previews when files change.
- Run modern frontend development tools and frameworks.
- Manage multiple projects and development servers.

**Core philosophy:** Make frontend development accessible on Android through a lightweight, integrated development environment.

Do not turn this application into a general-purpose Linux terminal or backend development environment. Frontend development is the primary focus.

---

## 2. Supported Technologies

The application must support three major categories of frontend development.

### A. Vanilla Web Development

Technologies:
- HTML
- CSS
- JavaScript

Requirements:
- No Node.js dependency.
- No build process required.
- Serve project files directly through a local HTTP server.
- Support standard HTML, CSS, JavaScript, images, fonts, and other static assets.
- Automatically refresh the browser when files change.

Preferred engine:
- Dart Shelf HTTP server.

### B. Higher-Level Web Development

Technologies:
- HTML
- Sass
- SCSS
- JavaScript

Requirements:
- Compile Sass and SCSS into CSS.
- Support nested selectors, variables, mixins, functions, and imports/modules.
- Automatically recompile styles when source files change.
- Refresh or update the preview when compilation finishes.
- Serve generated files through the local HTTP server.

The Sass compiler must operate locally on the device.

Do not require an external online compilation service.

### C. Modern Frontend Frameworks

Supported frameworks:
- React
- Vue
- Svelte

Supported languages:
- JavaScript
- TypeScript

Supported styling technologies:
- CSS
- Tailwind CSS
- Bootstrap
- Sass / SCSS where compatible.

Build tooling:
- Node.js
- npm-compatible package management
- Vite as the primary development server and bundler.

Requirements:
- Generate framework project templates.
- Support dependency installation.
- Support development scripts.
- Start and stop Vite development servers.
- Display server logs.
- Support Hot Module Replacement (HMR).
- Support TypeScript.
- Support compatible Tailwind CSS and Bootstrap configurations.
- Allow users to import existing compatible projects.

React, Vue, and Svelte must use their respective Vite integrations.

The application should not implement separate custom bundlers for each framework.

### Runtime Compatibility

Node.js must run locally on Android using an Android-compatible runtime.

Important considerations:
- Support Android ARM64.
- Investigate ARM32 compatibility where practical.
- Manage Node.js processes safely.
- Support npm package installation.
- Handle incompatible native Node.js dependencies gracefully.
- Do not assume desktop Linux binaries can run directly on Android.

Python, PHP, and other backend runtimes are outside the current project scope.

---

## 3. Core Application Architecture

Use a modular architecture with clear separation between the user interface, project management, and runtime execution.

Recommended structure:

```text
lib/
├── main.dart
│
├── core/
│   ├── models/
│   │   ├── project.dart
│   │   ├── project_config.dart
│   │   └── server_instance.dart
│   │
│   ├── services/
│   │   ├── project_manager.dart
│   │   ├── file_manager.dart
│   │   ├── server_manager.dart
│   │   └── port_manager.dart
│   │
│   └── engines/
│       ├── runtime_engine.dart
│       ├── static_engine.dart
│       ├── sass_engine.dart
│       └── node_engine.dart
│
├── window/
│   └── main.dart
│
├── features/
│   ├── dashboard/
│   ├── projects/
│   ├── editor/
│   ├── terminal/
│   ├── preview/
│   └── settings/
│
├── widgets/
│
└── utils/
```

This structure may evolve as the application grows, but preserve modularity.

### Architectural Rules

1. Keep UI code separate from server execution logic.
2. Do not put server implementation directly inside widgets.
3. Use services or managers for application-level operations.
4. Use models for structured project and server data.
5. Use a runtime abstraction to support different project types.
6. Avoid tightly coupling the application to Vite.
7. Make each runtime independently testable.
8. Keep project configuration persistent.
9. Support multiple projects.
10. Support multiple server instances when resources permit.

---

## 4. Runtime Engine Abstraction

All development engines should follow a shared interface.

Example:

```dart
abstract class RuntimeEngine {
  String get name;

  bool get isRunning;

  Stream<String> get logs;

  Future<void> start({
    required Project project,
    required int port,
  });

  Future<void> stop();
}
```

Expected implementations:

```text
RuntimeEngine
│
├── StaticEngine
│   └── Dart Shelf
│
├── SassEngine
│   ├── Sass compiler
│   └── Dart Shelf
│
└── NodeEngine
    ├── Node.js runtime
    ├── npm
    └── Vite
```

The Project Manager should determine which engine to use based on the project configuration.

The UI should not need to know the implementation details of the selected engine.

Prefer a consistent API such as:

```dart
await projectManager.start(project);
await projectManager.stop(project);
```

---

## 5. Project Management

Users must be able to:

- Create projects.
- Import existing projects.
- Rename projects.
- Delete projects.
- View project information.
- Browse project directories.
- Identify project types.
- Open recent projects.
- Configure project settings.

### Project Templates

Provide templates for:

**Vanilla**
- Basic HTML/CSS/JavaScript.

**Sass**
- HTML with Sass/SCSS compilation.

**React**
- React with JavaScript.
- React with TypeScript.

**Vue**
- Vue with JavaScript.
- Vue with TypeScript.

**Svelte**
- Svelte with JavaScript.
- Svelte with TypeScript.

Allow users to choose styling options where applicable:

- CSS
- Sass / SCSS
- Tailwind CSS
- Bootstrap

Use Vite for framework templates.

### Project Storage

Use Android's Storage Access Framework for importing user-selected project directories.

Provide an app-managed workspace for projects that require writable local files or runtime execution.

Do not assume that arbitrary Android storage paths are permanently accessible.

Persist project metadata and configuration locally.

---

## 6. Local Development Server

The application must provide a unified development server interface.

Requirements:

- Start server.
- Stop server.
- Restart server.
- Assign an available port automatically.
- Allow custom port configuration.
- Display the local server URL.
- Display server status.
- Capture server logs.
- Handle startup failures.
- Detect unavailable ports.
- Support multiple project instances.

### Localhost Configuration

For embedded WebView previews, prefer:

```text
http://127.0.0.1:<port>
```

Bind development servers to loopback by default.

Do not expose servers to external network interfaces unless the user explicitly enables network sharing.

When enabling network access, provide appropriate security controls.

---

## 7. WebView Preview

Use:

`webview_flutter`

Requirements:

- Display local development server URLs.
- Support JavaScript.
- Support browser refresh.
- Support back and forward navigation.
- Display loading indicators.
- Display navigation errors.
- Support responsive viewport testing.
- Support Vite HMR and WebSocket connections.
- Handle server shutdown gracefully.

The WebView must load the actual local HTTP server URL.

Do not replace the local HTTP server with direct HTML file loading.

---

## 8. Live Reload and HMR

Live reload is an essential feature.

### Vanilla Projects

Use file monitoring to detect changes.

When relevant files change:
1. Detect the modification.
2. Debounce rapid events.
3. Notify the preview.
4. Refresh the WebView.

### Sass Projects

When SCSS files change:
1. Recompile Sass.
2. Capture compilation errors.
3. Update the generated CSS.
4. Refresh or update the preview.

### Framework Projects

Use Vite's native HMR functionality.

Do not implement a competing custom HMR system for Vite projects.

Ensure WebSocket connectivity between the Vite server and the embedded WebView.

---

## 9. User Interface and Experience

The application should feel like a lightweight mobile IDE designed specifically for frontend development.

### Main Dashboard

Include:
- Application branding.
- Recent projects.
- Create project action.
- Import project action.
- Project list.
- Running server indicators.

### Project Workspace

Include:
- File explorer.
- Code editor.
- Preview browser.
- Server controls.
- Terminal or output panel.

Design for mobile screens first.

Use Material 3 and maintain a consistent design language.

The interface should be clean, modern, responsive, and easy to navigate.

Avoid unnecessary complexity.

---

## 10. Code Editor

The application should eventually provide an integrated code editor.

Required features:
- Syntax highlighting.
- HTML support.
- CSS and SCSS support.
- JavaScript and TypeScript support.
- File tabs.
- Search.
- Basic code formatting.
- File saving.
- Error indicators.

Keep the editor modular so it can be replaced or upgraded independently.

External editor integration may also be supported later.

---

## 11. Android-Specific Requirements

The application must be designed around Android constraints.

Consider:

- Android filesystem permissions.
- Storage Access Framework.
- Android-compatible Node.js binaries.
- Runtime process lifecycle.
- Memory consumption.
- CPU consumption.
- Battery usage.
- WebView compatibility.
- Background execution restrictions.

For servers that need to remain active while the application is minimized, investigate Android foreground services and persistent notifications.

Do not assume background processes will remain alive indefinitely.

Use loopback networking for local previews.

Avoid unnecessary broad storage permissions.

---

## 12. Development Roadmap

Implement features incrementally.

### Phase 1 — Core Foundation
- Flutter project setup.
- Application architecture.
- Dashboard.
- Project creation.
- Project importing.
- Static HTTP server.
- Embedded WebView preview.
- Start and stop controls.

### Phase 2 — Vanilla Development
- HTML/CSS/JS project templates.
- File explorer.
- File editing.
- File watcher.
- Automatic preview refresh.

### Phase 3 — Sass Support
- Sass/SCSS compiler.
- Compilation management.
- Automatic recompilation.
- Compilation error reporting.

### Phase 4 — Node.js Runtime
- Android-compatible Node.js integration.
- Process manager.
- npm integration.
- Package installation.
- Terminal output.
- Runtime lifecycle management.

### Phase 5 — Framework Support
- Vite integration.
- React templates.
- Vue templates.
- Svelte templates.
- JavaScript and TypeScript.
- Tailwind CSS.
- Bootstrap.
- HMR.

### Phase 6 — Developer Experience
- Multiple running servers.
- Responsive preview.
- Browser controls.
- Improved code editor.
- Terminal interface.
- Project settings.
- Performance improvements.

---

## 13. Coding Standards

Follow these conventions:

### Dart

- Use null safety.
- Prefer clear, descriptive names.
- Use `snake_case` for filenames.
- Use `UpperCamelCase` for classes.
- Use `lowerCamelCase` for variables and methods.
- Keep widgets small and reusable.
- Avoid unnecessarily large StatefulWidgets.
- Handle asynchronous operations safely.
- Check widget mounting before calling setState after asynchronous operations.
- Dispose of controllers and resources correctly.
- Avoid memory leaks.

### Architecture

- Follow separation of concerns.
- Keep business logic outside widgets.
- Prefer dependency injection where appropriate.
- Avoid duplicated functionality.
- Use interfaces for interchangeable runtimes.
- Handle exceptions explicitly.
- Write testable services.

### Performance

- Avoid unnecessary rebuilds.
- Debounce file watcher events.
- Manage server processes carefully.
- Avoid loading large files entirely into memory when unnecessary.
- Monitor memory usage.
- Ensure that stopped servers release their resources.

---

## 14. Instructions for AI Coding Agents

When working on this project:

1. Read this AGENTS.md before making changes.
2. Understand the existing project structure before implementing features.
3. Follow the established architecture.
4. Do not rewrite working modules unnecessarily.
5. Do not introduce backend runtime features outside the current scope.
6. Prioritize frontend development functionality.
7. Use Vite as the standard framework development server.
8. Do not simulate functionality that should be implemented for real.
9. Do not claim a runtime is supported unless it actually works on Android.
10. Use Android-compatible dependencies and binaries.
11. Handle permissions and process lifecycle correctly.
12. Test important functionality before considering it complete.
13. Keep documentation updated when architecture changes.
14. Prefer small, incremental implementations.
15. Explain important architectural decisions.

When implementing a feature, provide:
- Files created.
- Files modified.
- Dependencies added.
- Android configuration changes.
- Testing instructions.
- Known limitations.

If a requested feature is not technically feasible on Android as currently designed, explain the limitation and propose a realistic alternative instead of implementing a fake solution.

---

## 15. Product Vision

Kimmy Dev Server aims to become a mobile-first frontend development environment.

The ultimate goal is to let users:

1. Create a frontend project.
2. Write or import code.
3. Install compatible dependencies.
4. Start a local development server.
5. Preview the running website.
6. See changes through live reload or HMR.
7. Manage multiple frontend projects directly on Android.

The application should combine the convenience of Live Server with selected capabilities of a lightweight mobile IDE.

**Primary priority: Excellent frontend development and preview experience on Android.**

Build a reliable foundation first, then expand framework and tooling support without compromising the core experience.
