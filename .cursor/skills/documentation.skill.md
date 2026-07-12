---
name: documentation
description: Update documentation — which doc per change type, section templates
---

# Documentation Skill

Update project documentation when making changes.

## Update Map

| Change | Document(s) |
|--------|-------------|
| New package | `PACKAGE_GUIDE.md` |
| New feature | `FEATURE_GUIDE.md`, `ARCHITECTURE.md` |
| New API endpoint | `API_GUIDE.md` |
| New DS component | `DESIGN_SYSTEM.md` |
| Typography change | `TYPOGRAPHY.md` |
| New localization pattern | `LOCALIZATION_GUIDE.md` |
| Architecture change | `ARCHITECTURE.md`, `DEPENDENCY_GRAPH.md` |
| Security change | `SECURITY.md` |
| Routing change | `ROUTING.md` |
| Config/flavor change | `CONFIGURATION.md`, `FLAVORS.md` |
| Release | `RELEASE.md` |

## Section Template

```markdown
## <Feature Name>

**Package:** `packages/<name>/`
**Status:** Active | Stub | Orphaned
**Dependencies:** core, network, design_system

### Overview
Brief description of what this package/feature does.

### Key Classes
- `ClassName` — description

### Usage
\`\`\`dart
// Code example using actual project APIs
\`\`\`
```

## Quality Rules

- Use actual class names, paths, and commands from the codebase
- No stale examples — verify against current code before documenting
- Keep Mermaid diagrams in sync with actual `pubspec.yaml` dependencies
