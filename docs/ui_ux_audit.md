# Qikzoo Partner UI/UX audit

**Review date:** 1 August 2026  
**Method:** Source-level review of every routed screen and shared UI primitive,
existing widget tests, and the production layout rules. This review validates
structure, states, semantics, layout constraints, and interaction contracts.
It should be followed by a device pass on physical small, large, and tablet
hardware before release.

## Executive assessment

Qikzoo has a very good starting point: its spacing, radius, motion, CTAs,
loading skeletons, error views, input style, and core mobile navigation are
already purposefully designed. The product feels like a coherent delivery
partner app rather than a collection of generic Flutter screens.

The largest remaining product-quality risks are systemic rather than cosmetic:

1. Primary navigation previously became phone-only on wide windows. This is
   now fixed with an adaptive rail for the five main tabs.
2. Updates previously used a different four-destination navigation model. It
   is now a conventional detail route with a persistent title and Help action.
3. `ThemeMode.light` and direct `AppColors` usage mean the app is **not dark
   mode ready**. Do not enable a dark-mode switch until semantic color tokens
   replace direct light colors.
4. The app has many thoughtful per-screen empty, error, and loading states,
   but no shared offline/connectivity state. A rider should never need to infer
   whether an action has failed because they are offline.
5. A few dense operational rows and fixed 42px actions need large-text and
   touch-target review on real hardware.

## Scoring rubric

Scores are out of 10. `Ready` is the combined production-readiness score,
including state coverage, interaction clarity, responsiveness, and
maintainability.

| Screen | UI | UX | A11y | Perf | Consistency | Visual | Modern | Ready | Primary finding / direct solution |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| Splash | 8 | 8 | 8 | 10 | 9 | 9 | 9 | 8 | Strong branded start; keep the route decision interruptible and expose a short loading label. |
| Welcome | 9 | 8 | 8 | 9 | 9 | 9 | 9 | 8 | Good first impression; test compact landscape and make illustration purely decorative to screen readers. |
| Partner benefits | 8 | 8 | 8 | 9 | 9 | 9 | 9 | 8 | Good progressive onboarding; retain a visible skip/back path when launched from onboarding. |
| Mobile number | 8 | 9 | 8 | 9 | 9 | 8 | 9 | 8 | Clear first task; persist country context and use phone autofill where available. |
| OTP verification | 8 | 9 | 8 | 9 | 9 | 8 | 9 | 8 | Good focused flow; announce resend countdown/status changes to assistive tech. |
| Set password | 8 | 8 | 8 | 9 | 9 | 8 | 9 | 8 | Strength guidance is useful; make every requirement state semantic, not color-only. |
| Personal information | 8 | 8 | 8 | 9 | 9 | 8 | 8 | 8 | Form is scrollable; preserve focused field above keyboard and mark required labels in text. |
| Address | 8 | 8 | 8 | 8 | 9 | 8 | 8 | 8 | Location assistance reduces typing; make permission denial a first-class recovery state. |
| KYC | 8 | 8 | 8 | 8 | 9 | 8 | 8 | 8 | Good document choices; show supported formats, size limits, and upload progress before picker launch. |
| Vehicle registration | 8 | 8 | 8 | 8 | 9 | 8 | 8 | 8 | Bottom-sheet selection is appropriate; ensure selected vehicle is repeated in the confirmation CTA. |
| Emergency contact | 8 | 8 | 8 | 9 | 9 | 8 | 8 | 8 | Clear constrained form; add relationship-specific examples and phone validation feedback. |
| Review | 8 | 9 | 8 | 9 | 9 | 8 | 8 | 8 | Strong opportunity to catch errors; each edit action should return to its field with preserved form state. |
| Vehicle selection | 8 | 8 | 8 | 9 | 9 | 9 | 8 | 8 | Cards are discoverable; add selected-state text, not check/color alone. |
| Vehicle details | 8 | 8 | 8 | 9 | 9 | 8 | 8 | 8 | Field layout is consistent; use camera/photo affordances that state why a photo is required. |
| Delivery zone / city | 8 | 8 | 8 | 9 | 9 | 8 | 8 | 8 | Searchable choice flow is clear; add empty-search and service-unavailable states. |
| Document upload | 8 | 8 | 8 | 8 | 9 | 8 | 8 | 8 | Good progress structure; standardize per-file retry, replace, and remove feedback. |
| Selfie verification | 8 | 9 | 8 | 8 | 9 | 8 | 9 | 8 | Good task framing; make light/face quality feedback live and concise. |
| Selfie camera capture | 8 | 8 | 8 | 8 | 7 | 8 | 8 | 7 | Custom palette diverges from tokens; migrate to semantic colors and verify camera/error states on low-memory devices. |
| Welcome kit | 8 | 8 | 8 | 9 | 8 | 8 | 8 | 8 | Selection is engaging; summarize selected items above the CTA for long lists. |
| Payment coming soon | 7 | 7 | 8 | 10 | 9 | 8 | 8 | 7 | Avoid a dead end: offer a clear next step and opt-in notification. |
| Application under review | 8 | 8 | 8 | 9 | 9 | 8 | 8 | 8 | Status is understandable; include expected review window and support escalation. |
| Application submitted | 8 | 8 | 8 | 9 | 9 | 8 | 8 | 8 | Good completion state; provide a single, explicit expectation for what happens next. |
| Verification status | 8 | 8 | 8 | 9 | 9 | 8 | 8 | 8 | Useful progress view; pair every non-complete state with a single next action. |
| Approval | 8 | 8 | 9 | 9 | 9 | 8 | 8 | 8 | Strong state coverage; keep rejection reason selectable/copyable and action-oriented. |
| Agreement | 8 | 8 | 9 | 9 | 9 | 8 | 8 | 8 | Large-text scrolling is tested; make acceptance irreversible only after explicit confirmation. |
| Dashboard home | 9 | 9 | 8 | 8 | 9 | 9 | 9 | 9 | Excellent operational hierarchy; adaptive rail now makes it suitable for tablets. Validate polling feedback when the network is lost. |
| Gigs | 8 | 8 | 8 | 9 | 9 | 9 | 9 | 8 | Schedule-first structure works; add an empty-week explanation and next-best booking action. |
| Orders | 8 | 9 | 8 | 8 | 9 | 8 | 9 | 8 | Active order is prominent; filter chips should horizontally scroll or wrap at extreme text scales. |
| Incoming offer | 9 | 9 | 8 | 9 | 9 | 8 | 9 | 8 | High-priority decision is clear; haptics, expiry announcement, and a last-second grace rule need physical-device verification. |
| Active order | 9 | 9 | 8 | 8 | 9 | 8 | 9 | 8 | Timeline/handoff flow is strong; make cancellation consequences and offline proof queue explicit. |
| Order details | 8 | 8 | 8 | 9 | 9 | 8 | 8 | 8 | Information is well grouped; ensure address/contact actions have labels beyond icons. |
| Earnings | 9 | 8 | 8 | 8 | 9 | 9 | 9 | 8 | Strong data storytelling; chart must retain numerical summary and period state for screen readers. |
| Incentives | 8 | 8 | 8 | 9 | 9 | 8 | 8 | 8 | Clear secondary route; add eligibility and expiry directly beside every incentive. |
| Wallet / Pocket | 8 | 8 | 9 | 9 | 9 | 8 | 8 | 8 | Good large-text reflow; clarify whether Withdraw is an immediate action or payout education. |
| Notifications / Updates | 8 | 8 | 8 | 8 | 9 | 8 | 9 | 8 | Navigation is now consistent. Keep notification grouping and mark-all-read feedback for large lists. |
| Profile | 9 | 8 | 8 | 9 | 9 | 9 | 9 | 8 | Rich but legible surface; adaptive rail now improves wide-window use. Avoid color-only quick-action meanings. |
| Manage vehicle details | 8 | 8 | 8 | 9 | 9 | 8 | 8 | 8 | Solid account task; make save success durable and surface verification impact. |
| Manage documents | 8 | 8 | 8 | 8 | 9 | 8 | 8 | 8 | Statuses are useful; add upload queue/retry if network drops mid-upload. |
| Bank details | 8 | 8 | 9 | 9 | 9 | 8 | 8 | 8 | Sensible protection for financial data; mask sensitive numbers and explain verification time. |
| Training | 8 | 8 | 9 | 9 | 9 | 8 | 8 | 8 | Responsive actions are already tested; add resumable progress and completion confirmation. |
| Help & support | 8 | 8 | 8 | 8 | 9 | 8 | 8 | 8 | Bottom-sheet form respects keyboard insets; expose ticket SLA and attach evidence without leaving context. |
| Settings | 7 | 7 | 8 | 9 | 9 | 7 | 7 | 7 | Several entries lead to “coming soon”; hide unfinished actions or replace with real routes. Add theme only after semantic token work. |

## What is already working well

- A usable token foundation exists: `AppSpacing`, `AppRadius`, `AppShadows`,
  `AppTypography`, `AppMotion`, and `AppColors` prevent most visual drift.
- Primary CTAs have clear 52px height, loading states, touch feedback, and
  reduced-motion support.
- The app uses constrained content frames, `SafeArea`, scroll views, pull to
  refresh, skeletons, and purpose-built errors in the data-heavy paths.
- The onboarding and delivery flows use meaningful confirmation, handoff, and
  status patterns rather than optimistic silent state changes.
- Existing tests deliberately cover narrow displays, enlarged text, field
  flows, and operational states.

## Priority backlog

### Critical

| Issue | Why it matters | Production solution |
|---|---|---|
| No explicit offline model | Riders operate on unreliable networks; generic errors do not tell them whether queued actions are safe. | Add a connectivity provider, persistent offline banner, queued/idempotent delivery evidence uploads, and an “updated x min ago” timestamp for operational data. |
| Light-only color ownership | `ThemeMode.light` is hard-coded and light tokens are read directly across screens. Turning on dark mode now would produce incorrect surfaces and contrast. | Create semantic `ColorScheme`-backed surface/text/status tokens, migrate direct uses, add `AppTheme.dark`, then expose system/light/dark preference. |
| High-stakes action recovery | KYC, selfie, document, and active-order proof tasks are vulnerable to camera, permission, and network failures. | Give every failed submission a retained draft, retry/reselect action, clear error cause, and support fallback. |

### High priority

| Issue | Why it matters | Production solution |
|---|---|---|
| Tablet/foldable primary navigation | A floating bar with a narrow centered column wastes large windows. | **Implemented:** `AppTabScaffold` switches from the compact floating bar to a labelled `NavigationRail` at 720 logical px. |
| Conflicting Updates navigation | A separate four-item bar changed the information architecture mid-journey. | **Implemented:** Updates is now a normal route with a standard app bar and Help action. |
| Incomplete settings destinations | “Coming soon” actions reduce trust in a production settings surface. | Ship the destination before exposing it; otherwise use an explanation/roadmap surface outside Settings. |
| Dense operational content at 200% text | Order, notification, and status rows can lose hierarchy when labels wrap. | Test 320px/1.5–2.0x text on every high-stakes state; use `Flexible`, vertical action fallbacks, and two-line labels. |

### Medium priority

| Issue | Why it matters | Production solution |
|---|---|---|
| Direct one-off colors | Multiple screens define local hex values, which blocks theme support and subtly changes semantic meanings. | Consolidate status, tint, and foreground tokens; reserve local colors for illustrations only. |
| Inconsistent surface treatment | Some cards are bordered, some shadowed, and some use both without semantic distinction. | Adopt a three-level surface rule: default flat, grouped border, elevated only for temporary/floating surfaces. |
| Non-semantic data visualizations | Charts/colored states alone are inaccessible. | Pair every visual value/state with text, expose semantic summaries, and use icon/label as well as color. |
| 42px notification permission button | It is below the recommended 48px target for an independent action. | Raise it to 48px or make the whole card the tap target with a clearly labelled button. |

### Nice to have

| Opportunity | Production solution |
|---|---|
| Haptics | Use light haptics for online/offline, offer accept, QR/OTP success, and destructive confirmations; never rely on them as sole feedback. |
| Contextual education | Replace generic “coming soon” snackbars with a short explainer and notify-me option where a capability is genuinely pending. |
| Motion polish | Maintain the existing 160–380ms motion scale; use shared-axis for hierarchy moves and skip ambient shimmer/entrances when reduced motion is enabled. |
| Command shortcuts | Add keyboard focus/shortcuts for navigation rail and critical retry/back actions on tablet/desktop windows. |

## Design-system rules to adopt

| Area | Rule |
|---|---|
| Spacing | Keep the existing 4/8/16/24/32/40/56 scale. New components may not introduce arbitrary spacing unless it belongs to an illustration. |
| Touch targets | 48x48 minimum for independent actions; 52px remains the standard primary CTA height. |
| Typography | Use display for one focal metric, h1 for page hierarchy, h2 for grouped headings, body for readable content, caption only for supporting text. Never convey a required/error/selection state solely with color. |
| Surfaces | `background` for canvas; `surface` for content; one border for grouped forms/lists; one restrained elevation for floating/temporary affordances. |
| Status | Every success/warning/error/offline state requires icon + label + color. Use semantic tokens rather than local hex values. |
| Motion | Use `AppMotion` only; honor `MediaQuery.disableAnimations`; cap staggered entrances and never delay a time-sensitive delivery action. |
| Feedback | Mutations need a progress state, success acknowledgement, actionable error, and persistence/retry behavior when offline. |
| Responsive | Decide using `LayoutBuilder` width, not device type/orientation. Cap reading width; switch primary tabs to rail at 720px; test 320, 360, 390, 600, 720, and 1024px. |

## Implementation plan

| Improvement | Current issue / user benefit | Complexity | Effort | Performance impact |
|---|---|---:|---:|---|
| Adaptive main navigation | **Implemented.** Five primary tabs now retain a familiar bottom bar on phones and gain a labelled rail on wide windows, improving discoverability and use of tablet space. | M | 1–2 days | Negligible; layout-only branch. |
| Standard Updates route | **Implemented.** Removes the competing navigation model and gives users a predictable back stack and Help action. | S | <1 day | None. |
| Semantic theme migration | Makes dark mode, contrast tuning, and visual consistency safe across the app. | L | 1–2 weeks | Positive long-term; reduces repeated local styling. |
| Offline/retry framework | Makes earnings, orders, uploads, and proof resilient in weak network conditions. | L | 2–3 weeks | Small state overhead; avoid polling while offline. |
| Upload recovery | Prevents lost KYC/selfie/document work and support escalation. | M | 3–5 days | Use resumable/queued uploads; no large in-memory images. |
| High-text test matrix | Prevents clipping and lost actions at accessibility font sizes. | M | 2–3 days | Test-only impact. |
| Tokenize one-off colors | Makes semantic states consistent and prepares dark mode. | M | 3–5 days | None. |
| Finish/hide settings stubs | Restores credibility to account preferences. | M | 2–4 days per destination | None. |

## Verification still required before release

1. Test onboarding, active delivery, KYC/upload recovery, and offline recovery on
   a real small Android phone, a large Android phone, a tablet, and a foldable.
2. Repeat the same flows at 1.5x and 2.0x text size with TalkBack enabled.
3. Verify notification, camera, location, and phone permissions in denied,
   limited, and permanently denied states.
4. Record a low-end device performance trace for the dashboard poll, shimmer,
   camera capture, charts, and navigation transition.
5. Once semantic theming lands, run an automated contrast scan in both light
   and dark modes and ship only when all interactive text meets WCAG AA.
