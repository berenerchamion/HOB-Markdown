# ✨ House of Beor Markdown

Welcome to modern and lightweight macOS **House of Beor Markdown** designed with **Material Design 3 (Material You)** aesthetics!

This application is built with Google's Flutter SDK for cross-platform portability. It is optimized for Apple's macOS.

> [!TIP]
> **Drag and drop** any `.md` or `.markdown` file directly into this window from Finder to open it immediately, or press **⌘ + O** to browse your files.

---

## 🚀 Key Features

* **macOS Drag & Drop**: Drop markdown files anywhere on the app.
* **Material Design 3**: Modern color tokens, tonal elevation, and smooth typography.
* **Auto-Reload**: Automatically detects and reloads when your file is saved in external editors (VS Code, Obsidian, etc.).
* **Table of Contents (TOC)**: Collapsible sidebar with heading hierarchy and smooth scroll navigation.
* **Multi-View Modes**: Switch between **Rendered View**, **Split View**, and **Raw Source**.
* **Rich Code Highlighting**: Syntax-highlighted code blocks with 1-click copy action.
* **In-Document Search**: Press **⌘ + F** to find text.
* **Full Keyboard Shortcuts**: macOS command shortcuts for seamless workflow.

---

## ⌨️ macOS Keyboard Shortcuts

| Shortcut | Action |
| :--- | :--- |
| **⌘ + O** | Open file dialog |
| **⌘ + R** | Reload current file |
| **⌘ + B** | Toggle Table of Contents sidebar |
| **⌘ + T** | Toggle Light / Dark theme |
| **⌘ + F** | Search within document |
| **⌘ + =** | Zoom In (increase font scale) |
| **⌘ + -** | Zoom Out (decrease font scale) |
| **⌘ + 0** | Reset zoom to 100% |
| **⌘ + 1** | Switch to Rendered View |
| **⌘ + 2** | Switch to Split View |
| **⌘ + 3** | Switch to Raw Source View |

---

## 💻 Syntax Highlighting Examples

### Dart / Flutter
```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    title: 'MD Reader',
    home: Scaffold(
      body: Center(child: Text('Hello Material 3!')),
    ),
  ));
}
```

### TypeScript / React
```typescript
interface DocumentProps {
  title: string;
  wordCount: number;
  isFavorite?: boolean;
}

export const DocumentCard: React.FC<DocumentProps> = ({ title, wordCount }) => {
  return (
    <div className="p-4 rounded-xl bg-surface-container shadow-sm">
      <h3 className="font-bold text-lg">{title}</h3>
      <p className="text-sm text-slate-500">{wordCount} words</p>
    </div>
  );
};
```

### Python
```python
def calculate_read_time(word_count: int, wpm: int = 200) -> str:
    minutes = word_count / wpm
    if minutes < 1:
        return f"{round(minutes * 60)} sec read"
    return f"{round(minutes)} min read"
```

---

## 📊 Document Stats & Callouts

> [!NOTE]
> Material 3 uses subtle surface containers and high-contrast accents to make reading effortless and pleasing in both light and dark environments.

### Task Checklist
- [x] macOS native drag-and-drop support
- [x] Material Design 3 typography & theme tokens
- [x] Auto-reload file watcher
- [x] Split view & source view
- [x] Interactive Table of Contents sidebar

---

*Enjoy reading and editing your Markdown files!*
