# Chroma Sort (working title)

A color-sort puzzle game for iOS and Android, built in [Godot 4](https://godotengine.org/)
(GDScript). See [`docs/DESIGN.md`](docs/DESIGN.md) for the design principles
and monetization philosophy this project is built around.

## Getting started

1. Install [Godot 4.7+](https://godotengine.org/download) (standard build,
   not the .NET/Mono build — we're using GDScript, not C#).
2. Open Godot, choose **Import**, and select this folder (the one
   containing `project.godot`).
3. Run the project with `F5` / the Play button once a main scene exists.

## Project structure

```
scenes/      # .tscn scene files
scripts/     # .gd script files
assets/
  sprites/   # 2D art/placeholder shapes
  audio/     # sfx/music
addons/      # third-party plugins (e.g. IAP/billing wrappers)
docs/        # design notes
```

## Platform targets

- **Android** first — fastest iteration loop, no Mac required, one-time
  $25 Google Play Developer fee.
- **iOS** second — requires a Mac with Xcode and an Apple Developer
  Program membership ($99/yr) for the final build/signing/submission step.
