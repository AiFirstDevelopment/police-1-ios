# Claude Instructions for Police1

## Git Commit Policy

**NEVER commit changes unless explicitly asked by the user.**

Do not infer that a commit should be performed based on:
- Recent prompt history
- Completing a task
- Any implicit suggestion

Only commit when the user explicitly says something like "commit", "create a commit", "git commit", etc.

## Testing

**NEVER change tests unless explicitly asked by the user.**

Run view tests before suggesting code is complete:
```bash
xcodebuild test -project Police1.xcodeproj -scheme Police1 -destination 'platform=iOS Simulator,OS=latest,name=iPhone 16' -only-testing:Police1Tests/ContentViewInspectorTests
```
