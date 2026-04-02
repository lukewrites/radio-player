# Radio Player — Claude Instructions

## Versioning

This project follows **semantic versioning** (`MAJOR.MINOR.PATCH`) for every release.

Rules:
- **PATCH** (`1.0.x`): Bug fixes, crash fixes, small copy or layout tweaks — no new features
- **MINOR** (`1.x.0`): New user-facing features (e.g. Favorites, episode dedup, new views)
- **MAJOR** (`x.0.0`): Breaking changes, major redesigns, significant architecture shifts

When completing a feature or fix, update **both** values in `RadioPlayerApp.xcodeproj/project.pbxproj`:
- `MARKETING_VERSION` — bump according to the rules above (appears twice, one per build config)
- `CURRENT_PROJECT_VERSION` — increment by 1 (must be strictly increasing for App Store uploads)

Current versions:
- Marketing version: `1.0.0`
- Build number: `1`

## Development Workflow

- Follow strict TDD: write failing tests first, then implement
- Commit frequently with descriptive messages
- Use `gh` CLI for all GitHub operations
