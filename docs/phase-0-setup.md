# Phase 0 — Project Setup

**Status:** In progress
**Depends on:** nothing
**Spec reference:** see [SPEC.md](../SPEC.md) for tech stack rationale and repo conventions.

## Goal
Get an empty, runnable SwiftUI app in the iOS Simulator, backed by a public GitHub repo — before any real feature code exists.

## Scope
- [x] `git init` locally, create `SPEC.md`, `README.md`, `.gitignore`
- [x] Create public GitHub repo (`FrancisLozano/MacroPal`) and push
- [ ] Create the Xcode project: SwiftUI App template, iOS 17+ deployment target, SwiftData enabled
- [ ] Set the app's bundle identifier
- [ ] Lay out the folder structure from [SPEC.md §7](../SPEC.md#7-repository--git-workflow) (`Models/`, `Views/`, `ViewModels/`, `Engine/`, `Resources/`)
- [ ] Confirm the empty app builds and runs in the iOS Simulator
- [ ] Commit and push the project scaffold

## Definition of Done
An empty SwiftUI app builds and launches in the Simulator, the folder structure is in place, and it's pushed to GitHub — ready for Phase 1 feature code to land in the right places.
