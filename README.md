# Kimmy Dev Server (Frontend Editor)

A Flutter remake of [RyannKim327/Front-end-Editor](https://github.com/RyannKim327/Front-end-Editor)
that previews projects through a real local HTTP server instead of `file:///`.

The app keeps an editable HTML / CSS / JavaScript project in its documents
directory, serves that directory from `http://127.0.0.1:<port>/` with
[Shelf](https://pub.dev/packages/shelf), and loads the preview in a WebView.
Edits are auto-saved (debounced) and the preview reloads, similar to Live Server.

## Features

- Vanilla HTML/CSS/JS editor with file tabs.
- Auto-indent on newline: keeps the current indentation and adds a level after
  `{`, `(`, `[` or an opening HTML tag.
- Editor settings: font size, indent size (2 or 4 spaces), and text wrap.
- Local HTTP server bound to loopback only (`127.0.0.1`).
- Automatic port selection starting at `8080`.
- WebView preview loaded from the local server URL (not `file:///`).
- Debounced auto-save + live preview reload.
- Start / stop server and manual reload.
- Full-screen preview mode that hides the editor and app bar.
- Automatic desktop mode in landscape: desktop Chrome user agent and wide
  viewport (`setUseWideViewPort(true)`), reverting to mobile in portrait.
- Open an existing HTML/CSS/JS file into the workspace.
- Save the current file to a user-chosen location.
- Reset the project to the default template.
- Server request logs and editor font-size setting.
- Responsive split layout for portrait and landscape.

## Project structure

```text
lib/
├── main.dart
├── core/
│   ├── engines/
│   │   ├── runtime_engine.dart   # shared engine interface
│   │   └── static_engine.dart    # Shelf static server on 127.0.0.1
│   ├── models/project.dart
│   └── services/
│       ├── port_manager.dart
│       └── project_manager.dart
└── features/
    ├── editor/editor_panel.dart
    ├── preview/preview_panel.dart
    └── workspace/workspace_page.dart
```

## Running

```bash
flutter pub get
flutter run
```

On Android the workspace is created under the app documents directory
(`.../workspace`) with `index.html`, `styles.css`, and `script.js`.

The app declares `INTERNET` permission and enables cleartext traffic so the
WebView can reach `http://127.0.0.1`. The server itself only binds to loopback.

## Testing

```bash
flutter analyze
flutter test
```

`test/static_engine_test.dart` verifies that files are served over loopback,
that additional assets are served, that responses disable caching, and that
stopping the server releases its port.

## Known limitations

- Only vanilla HTML/CSS/JS is supported so far. Sass and Vite/Node projects are
  not implemented.
- A single workspace is managed; there is no project list or import of a whole
  directory yet.
- Live reload performs a full WebView reload rather than HMR.
- When text wrap is disabled, long lines scroll horizontally; the editor does
  not auto-scroll horizontally to follow the caret.
- Editor settings are kept for the current session only.
- The server is stopped when the app is disposed; there is no Android foreground
  service yet.
