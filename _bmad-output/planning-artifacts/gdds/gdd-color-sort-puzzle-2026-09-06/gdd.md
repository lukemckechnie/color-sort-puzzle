---
title: "Chroma Sort (working title) - Game Design Document"
game_type: "Puzzle"
platforms: "Android, iOS, macOS (Intel and Apple silicon), Windows, and web via itch.io"
created: 2026-09-06
updated: 2026-09-06
---

# Chroma Sort (working title) - Game Design Document

**Author:** Luke  
**Game Type:** Puzzle  
**Target Platform(s):** Android, iOS, macOS (Intel and Apple silicon), Windows, and web via itch.io

## Executive Summary

### Core Concept

Color Sort Puzzle is a compact color-sorting logic game. Players tap trucks to move same-color blocks onto a cyclic conveyor, then use timing and limited transit capacity to return blocks to compatible trucks and complete full monochrome sets. It should feel like Othello: simple rules and expertise earned by planning farther ahead.

### Target Audience

Idle and casual mobile players who want a low-friction puzzle they can also play on any device. They can improve a solved level through efficient capacity use, speed, and precision.

### Unique Selling Points

- A cyclic truck-and-conveyor puzzle with meaningful timing.
- Simple rules with forward-planning depth.
- Three simultaneous optimisation goals: peak occupancy, time, and taps.
- Fair free play across mobile, desktop, and browser platforms.

## Goals and Context

### Project Goals

- Make a puzzle that is easy to learn and rewards earned expertise.
- Sustain roughly one hour of play without boredom, as judged by the designer.
- Prove that a small, honest puzzle can earn money without dark-pattern or ad-farm tactics; v1 validates the core loop while remaining free.

### Background and Rationale

A color may be parked in a wrong-capacity truck, even when that truck is full, but that stack remains movable and cannot complete or satisfy the win. A truck completes only when it is full and monochrome, and its capacity matches that color's total set size. Space management and future planning—not simple container shuffling—are the puzzle.

## Core Gameplay

### Game Pillars

1. **Simple rules, earned expertise:** players quickly understand the interaction; stronger play comes from reading positions and future consequences.
2. **Forward planning under constraint:** the central skill is sorting trucks while transit capacity is tight.
3. **Optimisation is optional depth:** players can improve a win through lower peak occupancy, time, and taps.
4. **Play anywhere, fairly:** every target has the same rules; payment never reduces challenge or pacing.

### Core Gameplay Loop

1. Inspect truck contents, conveyor occupancy, and available information.
2. Tap a truck to unload its contiguous top-color run within free conveyor capacity.
3. Each unloaded block enters at its truck's exit, pushing blocks along the belt; every resulting arrival is offered to the truck at that position.
4. Use accepted blocks and freed space to prepare the next useful unload.
5. Leave every truck empty or completed and no blocks in transit, then replay for a better result or advance.

### Win/Loss Conditions

Win when no blocks remain in transit and each truck is empty or completed. A truck completes only when full, monochrome, and matched to its color set size.

Loss occurs only after a successful unload when the conveyor is at authored capacity and no transit block can be accepted. A full conveyor alone is not a loss; it keeps circulating. Invalid or blocked taps leave state unchanged.

One result modal communicates either terminal outcome. On a win it offers Next Level when another level in the active pack exists; on a loss it offers Retry. Back always returns to that pack's level grid.

## Game Mechanics

### Primary Mechanics

- Trucks unload contiguous top-color runs.
- The cyclic conveyor has one authored transit capacity; its rendered geometry is not a second capacity.
- An unfinished truck with room accepts an unclaimed color when empty, or a block matching its current top color.
- A run records elapsed time, accepted taps, and peak conveyor occupancy.

### Controls and Input

The player selects one unambiguous truck with touch or pointer input. The game avoids precision dragging and rapid-input requirements. [NOTE FOR DESIGNER: resolve the whole-truck versus dedicated-Tap-target interaction and define keyboard and assistive-input behaviour.]

## Puzzle Specific Design

### Core Puzzle Mechanics

Players plan around limited transit, truck capacity, color compatibility, and the order blocks return around the ring. A block can return to its source only after a full loop.

### Puzzle Progression

- **Practice:** a separate replayable set teaches unloading/circulation, set size versus capacity, tight-capacity timing, and matching-color anchors.
- **Tier 1:** five fully visible tight-capacity levels.
- **Tier 2:** five levels with hidden individual blocks. A hidden block appears as a grey question-mark block and reveals when the player moves the block immediately above it in the truck.
- **Tier 3:** five levels with hidden blocks and trucks revealed by completing a specified color. Before it is available, a truck is covered by a tarp matching its required completion color.
- **Tier 4:** intentionally undecided.

### Level Structure

Practice is outside the star-gated progression. Main levels unlock linearly. Later tiers require enough stars from earlier levels; a 2.5-star average is provisional. Begin with five levels per tier and reassess completeness through play.

### Player Assistance

v1 provides no reset, undo, hint, or level-skip assistance. Retry after a loss is the only recovery action. v1 also does not sell hints, extra moves, undos, time skips, or challenge-reducing help.

### Replayability

One star is awarded for each level-specific target: win with peak occupancy below full authored capacity, complete within the time target, and complete within the tap target. All three can be earned in one run. The stored rating is the highest total from one successful run; stars never accumulate across runs. Most levels are expected to require three stars for progression. [NOTE FOR DESIGNER: define and playtest thresholds.]

## Progression and Balance

### Player Progression

The player first masters visible capacity management, then infers hidden blocks, then incorporates color-gated truck reveals into plans. Tier gates demonstrate competence before adding incomplete information.

### Difficulty Curve

Difficulty rises through deeper planning, not obscured rules or paid relief. Tier 1 tightens capacity. Tier 2 hides blocks as visible grey question-mark blocks; moving the block directly above one reveals it. Tier 3 combines hidden blocks with trucks covered by a tarp matching the color that unlocks them. Tier 4 remains open.

### Economy and Resources

The conveyor is the only gameplay resource. v1 is free and may offer a plainly worded, skippable tip-the-developer button with no gameplay benefit or penalty for declining. Prompts must not use urgency, FOMO, or countdown pressure. Future monetisation may only remove earned friction or provide cosmetics; it must not sell unsolved-puzzle advantages, time/energy skips, forced ads, or nagging.

## Level Design Framework

### Level Types

Practice, Tier 1 visible, Tier 2 hidden-block, Tier 3 hidden-block plus color-gated reveal, and an undecided Tier 4.

### Level Progression

Each level defines starting stacks, truck capacities, color set sizes, conveyor capacity, and three star thresholds. Tier mechanics add only their stated concealment or reveal rules. Levels must be solvable without paid help. CI must verify solvability with an automated solver, and every level must be human-playtested before it is added. [NOTE FOR DESIGNER: define Tier 4 and the final gate calculation.]

## Art and Audio Direction

### Art Style

The presentation is minimal, colorful, clear, and fast to load. Art must make colors, capacity, occupancy, hidden information, reveals, completion, and failure legible. Programmer art is acceptable early; themes and palettes are cosmetic and replaceable.

### Audio and Music

Audio should confirm taps, acceptance, completion, reveals, wins, and losses without pressure. [NOTE FOR DESIGNER: define mood, accessibility controls, and v1 audio scope.]

## Technical Specifications

### Performance Requirements

The game is a 2D Godot 4.7+ standard GDScript project and must remain responsive on mobile, desktop, and browser targets. [NOTE FOR DESIGNER: set measurable frame-rate, load-time, memory, and web-download targets.]

### Platform-Specific Details

Android is the first native iteration target, then iOS. First release also includes Intel/Apple-silicon macOS, Windows, and itch.io web. Rules, levels, and scoring remain equivalent across targets.

Android release requires Play developer registration. iOS release requires a Mac with Xcode and Apple Developer Program membership.

### Asset Requirements

Replaceable assets are needed for blocks, trucks, belt, tap controls, terminal states, hidden blocks, gated trucks, stars, menus, and the optional tip button. [NOTE FOR DESIGNER: set resolution, localisation, and accessibility requirements.]

## Development Epics

### Epic Structure

See [epics.md](epics.md) for the detailed sequence: visible core, practice/Tier 1, stars/gates, Tier 2, Tier 3, cross-platform readiness, and presentation/fair support. Tier 4 is deferred.

## Success Metrics

### Technical Metrics

- Playable releases on all stated targets with rule and star-score parity.
- [NOTE FOR DESIGNER: define quantitative performance targets.]

### Gameplay Metrics

- The designer judges the game provides about one hour of engaging play.
- A player learns visible rules through practice and progresses without purchase.

## Out of Scope

- Tier 4 until its mechanic is designed.
- Procedural generation, daily/weekly puzzles, leaderboards, social systems, and a full economy.
- Paid hints, extra moves, undos, time skips, energy systems, forced ads, or rewarded-video walls.

## Assumptions and Dependencies

- Godot exports the same puzzle to every stated target, including an itch.io-compatible web build.
- The designer will later define Tier 4, exact thresholds, performance targets, audio, accessibility, and assistance policy.
- Whether levels beyond the initial planned catalog are hand-authored or generated remains open.
