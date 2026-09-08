# Decision Log — Color Sort Puzzle GDD

| Date | Decision | Rationale | Status |
| --- | --- | --- | --- |
| 2026-09-06 | Created GDD workspace. | No prior GDD draft exists. | Active |
| 2026-09-06 | v1 targets Android, iOS, macOS on Intel and Apple silicon, Windows, and web distribution through itch.io. | The game should be simple enough to play anywhere. | Active |
| 2026-09-06 | The intended feel is Othello-like: simple rules with expertise earned through play. | This is the game’s design north star. | Active |
| 2026-09-06 | Mastery is planning farther ahead; players may value solving with less offered conveyor capacity or in less time. | Different players may prefer different measures of strong play. | Active |
| 2026-09-06 | Withholding information that enables forward planning is a candidate source of complication. | The exact hidden information remains unresolved. | Open |
| 2026-09-06 | The inspiration uses hidden individual blocks and trucks revealed by completing a specified color. | These are reference mechanics only; adoption for this game is undecided. | Open |
| 2026-09-06 | The first difficulty escalation tier uses both hidden individual blocks and color-gated truck reveals. | These create incomplete-information planning after the visible puzzle is understood. | Active |
| 2026-09-06 | The next difficulty escalation tier is not yet decided. | Do not invent a later mechanic. | Open |
| 2026-09-06 | Supersedes the earlier tier definition: Tier 1 is fully visible; Tier 2 adds hidden individual blocks; Tier 3 adds color-gated truck reveals; Tier 4 is undecided. | The earlier entry incorrectly treated both hidden information mechanics as the first escalation tier. | Active |
| 2026-09-06 | Tier 1 mastery is moving blocks into sorted trucks under tight conveyor-capacity limits. | This is the capability players develop before hidden information is introduced. | Active |
| 2026-09-06 | Progression is linear, with later tiers gated by stars earned on earlier levels. | Tier access reflects demonstrated mastery rather than only completion. | Active |
| 2026-09-06 | An average of 2.5 stars is a candidate tier-gate threshold. | Exact threshold remains open. | Open |
| 2026-09-06 | Proposed star model: one star for meeting each level-specific threshold across capacity, completion time, and tap count. | The exact metric semantics and thresholds remain open. | Open |
| 2026-09-06 | The capacity-efficiency star is earned by winning with peak conveyor occupancy below the level’s full capacity. | The player does not choose a lower conveyor limit before the run. | Active |
| 2026-09-06 | A single successful run can earn all three stars; most levels require all three for tier progression. | Players must demonstrate efficiency, speed, and low tap count together. | Active |
| 2026-09-06 | A level stores the highest star total from one successful run; stars do not accumulate across attempts. | A three-star rating represents a complete performance in one attempt. | Active |
| 2026-09-06 | Start with five levels per tier, then assess whether the game feels complete. | Scope should be informed by play rather than a prematurely large level count. | Active |
| 2026-09-06 | Tutorials are separate practice levels, not part of tiered progression or its star gates. | The linear, star-gated progression begins with five Tier 1 levels. | Active |
| 2026-09-06 | Use Express GDD drafting mode. | Resolve only critical remaining gaps before drafting the full document. | Active |
| 2026-09-06 | Target idle and casual mobile players, with the option to play on any device. | The game should be accessible across mobile, desktop, and web. | Active |
| 2026-09-06 | v1 is free and may include an optional tip-the-developer button. | Core gameplay is validated before monetisation; the tip gives no gameplay benefit. | Active |
| 2026-09-06 | The 2.5-star tier gate remains provisional. | It will be adjusted through playtesting if necessary. | Active |
| 2026-09-06 | First-release completion is judged by the designer: roughly one hour of gameplay without boredom. | The initial catalog should be expanded based on this judgement. | Active |
| 2026-09-06 | Drafted the GDD and detailed epic outline in Express mode. | Remaining unresolved items are marked in the GDD for later design work. | Draft |
| 2026-09-06 | Reconciled the draft with existing design inputs. | Restored fair-business constraints, parking/insertion rules, terminal player flow intent, platform dependencies, and working-title status; retained unresolved decisions as notes. | Draft |
| 2026-09-06 | A hidden block displays as a grey question-mark block and reveals when the player moves the block directly above it in its truck. | Tier 2 uncertainty is visible and its reveal condition follows from player action. | Active |
| 2026-09-07 | A gated Tier 3 truck is covered by a tarp matching the color whose completed set unlocks it. | The player can see the required completion color without seeing the gated truck. | Active |
| 2026-09-07 | CI must verify every level with an automated solver, and each level must be human-playtested before it is added. | This guarantees a solvable level and checks its player experience. | Active |
| 2026-09-07 | v1 has no reset, undo, hint, or level-skip assistance; Retry is the only loss recovery action. | The puzzle does not include challenge-reducing assistance in its first release. | Active |
