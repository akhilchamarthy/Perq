# Perq — Product Requirements Document

**Author:** Product (PM hat, written from a reverse-engineered codebase)
**Status:** Draft v1 — reverse-engineered from `master` @ 2026-05-04
**Owner (eng):** TBD
**Reviewers:** Eng lead, Design lead, Growth, Legal/Privacy

> **Stack note:** The brief described the app as React. The codebase is actually a native **SwiftUI / iOS 17+** app using SwiftData, CoreLocation, MapKit POI search, and UserNotifications. This PRD reflects what's built. If a React/web version is part of the long-term vision, that needs to be a separate scoping conversation — not a rewrite assumption.

---

## 1. Executive Summary

### Product overview
Perq is a privacy-first iOS app that helps people who hold multiple premium credit cards extract maximum value from the benefits they already pay for. Users add their cards from a curated catalog (Chase, Amex, Citi, Capital One, etc.), and Perq tracks expiring statement credits, memberships, and status benefits. At point-of-sale, a location-aware recommendation tells the user which card to pay with for the highest reward rate.

### Business rationale
Premium card holders pay $95–$695 in annual fees per card and reliably leave 30–60% of bundled credits on the table (Amex Platinum has 15+ separate credits across Uber, Saks, Equinox, Walmart+, Hotel Collection, etc.). The market is large and growing: ~67M premium cards in the U.S., with the average affluent household holding 3+ rewards cards. There is no dominant consumer app in this space — incumbents (MaxRewards, AwardWallet, CardPointers) are either feature-thin or rely on bank-credential aggregation that scares users off.

Perq's wedge is **no bank auth, manual-but-fast tracking, and a smart "tap this card here" nudge**. That's a differentiated, privacy-respecting position with low CAC potential (organic word-of-mouth in the points/miles community).

### Core value proposition
> "Stop letting card benefits expire. Pay with the right card every time. No bank login, no exported statements — your data stays on your phone."

---

## 2. Problem Statement

### User pain points
1. **Benefit forgetfulness.** Cards bundle dozens of credits with different reset cadences (monthly, quarterly, semi-annual, annual). No one remembers them all.
2. **Wrong-card-at-checkout.** Users carry 3–6 cards and default to whichever is in Apple Wallet, leaving 2–4% in rewards on the table per swipe.
3. **Annual-fee anxiety.** Holders of $400+ AF cards rarely know whether they're "winning" the fee. Many cancel valuable cards out of guilt rather than data.
4. **Privacy gap.** Existing aggregators (Plaid-based) require full bank credentials. Many premium cardholders refuse to give a third party read access to their checking account.

### Market / user need
The points-and-miles enthusiast community (r/CreditCards, r/awardtravel, The Points Guy audience) numbers in the millions and over-indexes on willingness to pay for tools that maximize rewards. They are a beachhead, not the ceiling — the broader market is anyone holding 2+ rewards cards (estimated 80M+ U.S. adults).

### Why this matters
Even at modest engagement (one prevented expiration per month, $25 average benefit value), the user-perceived savings exceed any reasonable subscription price by 5–10x. That is a strong willingness-to-pay signal and a defensible TAM if monetized.

---

## 3. Goals and Non-Goals

### Goals
- **G1.** First-time user can add 3 cards and complete a "first benefit claim" within 5 minutes of install.
- **G2.** ≥60% of MAUs claim at least one benefit per calendar month after week 4.
- **G3.** Location-based card recommendations achieve ≥25% tap-through rate when shown.
- **G4.** Catalog covers ≥95% of cards held by U.S. premium cardholders (top ~80 SKUs).
- **G5.** D30 retention ≥35% (high bar but appropriate for a utility app with monthly value events).

### Non-Goals (V1)
- No bank-credential aggregation (Plaid, Finicity). Privacy is a feature, not a temporary stance.
- No automatic transaction matching. Manual claim is the contract.
- No social / sharing / referral mechanics until core retention is proven.
- No multi-currency or non-U.S. issuer catalog.
- No Android. iOS-first; Android is post-PMF.
- No web companion. Mobile-only until usage justifies otherwise.

---

## 4. Target Users

### Primary persona — "Maximizer Marcus"
- 28–42, urban, $150K+ HHI, 3–6 rewards cards including at least one premium card.
- Reads The Points Guy, lurks r/CreditCards.
- Motivated by ROI and the meta-game of squeezing fees.
- Behaviors: checks balances 3x/week, plans dining around 5x categories.

### Secondary persona — "Status-quo Sarah"
- 32–55, affluent professional, holds 2–3 cards including a premium one (often Amex Gold or CSP).
- Got the card for the lounge or a sign-up bonus.
- Motivated by guilt-prevention ("I'm paying for this — am I using it?").
- Behaviors: passive; will respond to push notifications but won't open the app daily.

### Tertiary — "Travel Hacker Tariq"
- Optimization fanatic with 8+ cards across spouse + self for manufactured spend / category coverage.
- Power user; small but vocal cohort that drives word-of-mouth.

### What the codebase currently optimizes for
Today's UX assumes the Maximizer. The empty state, no onboarding, and manual benefit-claim model push Sarah out the door. **Fixing onboarding is the single biggest growth lever in this PRD.**

---

## 5. User Stories

### P0 — Critical
- As a new user, I want a 3-screen onboarding that explains the value and walks me through adding my first card, so that I don't bounce on an empty screen.
- As a user, I want to receive a push notification before a benefit expires (not just when I open the app), so that I never miss a credit.
- As a user, I want to see all benefits expiring in the next 60 days (not just this month), so I can plan ahead.
- As a user, I want to add and edit a custom card with my own benefits and cashback categories, so that uncatalogued cards are still usable.
- As a user with location enabled, I want a non-intrusive in-app banner suggesting the best card when I'm at a merchant, so I tap the right card.

### P1 — Important
- As a user, I want to mark a card's renewal date and get a "is this still worth it?" summary 30 days before it auto-renews, so I can decide whether to product-change or cancel.
- As a user, I want a dashboard showing total benefit value extracted vs. total annual fees paid, so I can see ROI per card.
- As a user, I want the catalog to refresh from a remote source, so my benefits stay current when issuers change them.
- As a user, I want a Home Screen widget showing the next expiring benefit, so I don't need to open the app.
- As a user, I want iCloud sync, so adding a card on my iPhone is reflected on my iPad.
- As a user, I want category-based "best card" lookup without needing to be at a location, so I can plan an Amazon purchase from my couch.

### P2 — Nice-to-have
- Apple Watch complication.
- Live Activity that surfaces the recommendation on the Lock Screen during dwell.
- Spending-goal tracking ("hit $4K to keep Platinum 1.5x").
- CSV/PDF export of claimed benefits (tax/expense use cases).
- Shared-household wallet (paired Apple IDs).
- Apple Wallet pass integration (deep-link to the right card).

---

## 6. Functional Requirements

### 6.1 Wallet Management
**Description.** User adds, removes, and edits credit cards from a curated catalog or as fully custom entries.

**Requirements.**
- Browse cards by issuer (12 issuers ship in V1).
- Add card with one tap; pre-populated benefits and cashback categories applied.
- Custom card flow accepts name, issuer (free-text), network, annual fee, color, and an editor for benefits + cashback categories. **Today the custom flow only accepts name + fee, which is shipped-incomplete.**
- Edit existing card (today this is a TODO stub on `CardDetailView`).
- Swipe-to-delete with confirm dialog.
- Replace-card flow when re-adding a card already in wallet (preserves nothing — destructive, with confirm).

**Edge cases.**
- User adds the same card twice → already handled via replace flow; ✅
- User has 50+ cards → list virtualization needed; current LazyVStack is fine, but the duplicate `CardDataManager` instantiation between `MainTabView` and `CardListView` is a bug — fix to single source of truth.
- Cards.json fails to load → today logs and shows empty Issuer grid; needs a friendly error state and retry.

**Validation rules.**
- Annual fee: numeric, ≥0, ≤9999.
- Custom card name: 1–60 chars, trim whitespace.
- Card color: must be valid hex; today `Color(hex:)` fails silently to gray.

**Dependencies.** SwiftData store, `cards.json` bundle resource.

---

### 6.2 Benefit Tracking & Claim
**Description.** Per-benefit progress tracking with period-aware claim toggles.

**Requirements.**
- Each benefit has a reset period (monthly, quarterly, semi-annual, annual, quadrennial, one-time).
- Period grid renders for the current year, with past/current/future state styling.
- Claim toggle per period; recomputes `usedAmount` based on `totalAmount / numberOfPeriods × claimedCount` for the current year.
- Filter by benefit type (Credit, Membership, Status).
- Completed benefits collapse into a separate section.

**Edge cases.**
- Mid-month signup → past-period buttons appear "missed" (rose). Should be a configurable signal — user may not have held the card during those months. **Add a `cardEnrolledFromDate` to suppress incorrect "missed" styling.**
- Year rollover → claimed periods from prior year remain in `claimedPeriods` array but don't render. Verify analytics queries filter by year.
- Benefit with no `totalAmount` (e.g., status perks) → button toggles enrollment, not amount. Today this works.
- Quadrennial / one-time benefits → grid logic falls through to single button. Verify reset semantics for one-time (should never reset).

**Validation rules.**
- `usedAmount` cannot exceed `totalAmount` (enforced in `useAmount` but bypassable via `togglePeriod` — re-audit math).
- Claimed period IDs must follow `YYYY-Mxx`, `YYYY-Qx`, `YYYY-Hx`, `YYYY-A` schema.

**Dependencies.** `Benefit` model, `BenefitTracker` service.

---

### 6.3 Reminders & Notifications
**Description.** Surface unclaimed benefits before they reset; deliver push notifications.

**Requirements.**
- Reminders tab lists upcoming expirations sorted by urgency.
- Urgency levels: critical (≤3 days), high (≤7), medium (≤14), low (>14).
- Local push notifications fire ≥7 days before benefit reset (configurable).
- Notification deep-links to the benefit row in `CardDetailView`.

**Critical gap.** Today `BenefitTracker.checkForExpiredBenefits()` only surfaces benefits whose period ends **in the current calendar month**. A quarterly benefit ending in 35 days is invisible. Reminders must use a forward window (e.g., next 60 days) and let urgency styling do the prioritization. The README also claims scheduled push notifications, but **no code path actually schedules them** — `NotificationManager` only fires recommendation notifications. This is a shipping-incomplete feature.

**Edge cases.**
- User denies notification permission → still show in-app reminders; explain in Settings.
- Permission revoked later → detect and prompt re-grant.
- Background app refresh disabled → schedule still works for `UNCalendarNotificationTrigger` since it's local; verify.

**Validation rules.**
- One notification per benefit per period; idempotent re-schedules.

**Dependencies.** `UNUserNotificationCenter`, BenefitTracker, settings store.

---

### 6.4 Location-Based Card Recommendations
**Description.** When the user dwells at a relevant merchant, surface the best card for that category.

**Requirements.** (already implemented thoughtfully)
- 30m radius POI search via `MKLocalPointsOfInterestRequest`.
- 45-second dwell requirement.
- Speed filter (≤1.8 m/s) to suppress drive-bys.
- Accuracy filter (≤25m horizontal accuracy).
- 500m cooldown to prevent re-firing.
- In-app banner if foregrounded; push notification if backgrounded.

**Critical gaps.**
- **Apples-to-oranges comparison.** `bestCard()` picks max `rate` regardless of unit. A 5x points card "beats" a 4% cashback card even if the points are worth less. Add a normalization factor (default cents-per-point per issuer; user-overridable in Settings).
- **No active-benefit filter.** A card whose category-bonus credit is exhausted should not be recommended.
- **MKLocalSearch coverage is patchy.** Outside major metros, POI categorization misses. Add a fallback: user can long-press the banner to manually select category.
- **No off-location lookup.** "I'm shopping on Amazon from my couch" has no flow today. Add a category picker on the home tab.

**Edge cases.**
- POI has no name → today returns nil; ✅
- Multiple matching POIs → today picks closest; ✅
- User declines location → recommendation feature silently inert. Show a one-time explainer in onboarding.
- Background "Always" permission denial → only when-in-use works; degrade gracefully.

**Validation rules.**
- Category key whitelist: `dining`, `groceries`, `gas`, `travel`, `ride_share`, `streaming`, `other`.

**Dependencies.** `LocationManager`, `PlaceRecommendationManager`, MapKit, `NotificationManager`.

---

### 6.5 Cashback / Best Rate Analytics
**Description.** "Analytics" tab shows the highest reward rate per category across the user's wallet.

**Requirements.**
- For each category key, find the card with max rate.
- Group/sort by rate descending.
- Tap a row to jump to that card.

**Critical gap.** This is a static lookup table, not analytics. It does not show **value extracted, value left on the table, fee ROI, or trend over time** — which is what users actually want. Either rename the tab "Best Cards" and add a real Analytics tab (recommended), or rebuild this surface entirely.

**Dependencies.** `CardDataManager`, all wallet data.

---

### 6.6 Settings
**Description.** App-level configuration.

**Requirements (today).** Dark-mode toggle. That's it.

**Critical gap.** README documents "configurable advance reminder days" — not in the UI. Add:
- Notification toggle + advance-days slider (1, 3, 7, 14, 30).
- Location permission status + deep-link to system settings.
- iCloud sync toggle (V2).
- Currency (V2).
- Points/miles valuation overrides per issuer.
- Data export (CSV).
- Reset wallet / delete all data.

---

## 7. Technical Requirements

### Architecture (current)
- **UI:** SwiftUI, iOS 17+, MVVM-lite (`@StateObject` view models)
- **Persistence:** SwiftData, on-device SQLite, cascading relationships, no migration policy declared
- **Services:** Singleton-style ObservableObjects (`LocationManager`, `PlaceRecommendationManager`, `BenefitTracker`, `CardDataManager`, `NotificationManager`)
- **Catalog:** Bundled `cards.json`

### Recommendations
1. **Move catalog to a remote, versioned source** (Cloudflare Worker + R2, or Firebase Hosting). Bundle stays as fallback. Cache locally with ETag / `If-Modified-Since`. Catalog goes stale fast in this category.
2. **Single source of truth for `CardDataManager`** — currently instantiated separately in `MainTabView` and `CardListView`, which can drift. Inject via `@Environment` or `@EnvironmentObject` from `PerqApp`.
3. **iCloud (CloudKit) sync** via `ModelConfiguration(cloudKitDatabase: .private)`. Critical for multi-device users. Plan migration carefully; SwiftData CloudKit has known quirks.
4. **Schema migration plan.** SwiftData needs `VersionedSchema` and `SchemaMigrationPlan` if any model changes. Today there is none — first model change will crash the store. Add this **before** the V2 milestone.
5. **Background tasks.** Use `BGAppRefreshTask` to reconcile period rollovers and re-arm notifications without depending on app open.

### Security & privacy
- All data on-device — keep this as a privacy promise and put it in the App Store listing.
- No tokens, no banking credentials. Don't add any.
- Location: request `whenInUse` first, escalate to `always` only after demonstrated value (after 1st banner shown). **Today the app immediately requests `always` — this is a permission-prompt anti-pattern that increases denial rate.**
- Notifications: request lazily after the user adds their first card, not on app launch.
- App Privacy manifest — declare data collection (none) and required reason API for `UserDefaults`, `FileTimestamp`, and disk-space.

### Performance
- Cold start <1.5s after splash (current splash is 1.8s artificial — cut to 0.6s once data load is verified).
- POI search debounced to 15m of movement; ✅
- LazyVStack for cards; OK up to ~200 rows. Beyond that, switch to `List`.

### Observability
- Today: `print()` statements only. **Ship-blocker for serious analytics.**
- Add structured event logging via OSLog + a privacy-respecting analytics SDK (PostHog self-hosted or Aptabase). Events: card_added, benefit_claimed, recommendation_shown, recommendation_tapped, notification_delivered, notification_opened, permission_granted/denied.
- Crash reporting via Apple's MetricKit (no third-party SDK needed for V1).

---

## 8. UX / Product Flow

### First-run journey (proposed)
1. **Splash** (0.6s, current is 1.8s — too long).
2. **Onboarding 3-up.** "Track every benefit. Pay with the right card. Your data stays on your phone." (Today: missing entirely; users land in empty state.)
3. **Add your first card.** Issuer grid prefilled with the 4 most popular issuers up top.
4. **Notification permission prompt** with explanation: "We'll remind you before benefits expire."
5. **Location permission prompt** with explanation: "We'll suggest the best card when you're shopping." `whenInUse` only; defer `always` until value demonstrated.
6. Land on Cards tab, populated.

### State map
- **Loading:** splash + spring animation (today: present, too long)
- **Empty (Cards):** illustration + CTA "Add your first card" (today: present, dry copy)
- **Empty (Reminders):** "All caught up" (today: present, ✅)
- **Empty (Analytics):** "Add cards to see best rates" (today: present, ✅)
- **Error (catalog load fail):** **missing** — needs retry button
- **Permission-denied banners:** **missing** for both location and notifications
- **Network offline:** N/A today (no network calls); will need handling once catalog is remote
- **Recommendation banner:** spring-in from top, 8s auto-dismiss, X to dismiss (today: present, ✅)

---

## 9. Success Metrics

### Activation (D0–D7)
- % of installs that add ≥1 card (target: 70%)
- % of installs that complete onboarding (target: 80%)
- Time-to-first-benefit-claim (target: median ≤7 days)
- Notification permission grant rate (target: 60%+)
- Location permission grant rate (when-in-use, target: 50%+)

### Engagement (W2–W4)
- Weekly claim rate (% MAU claiming ≥1 benefit/week)
- Recommendation tap-through rate (target: 25%+)
- Median session count per active week (target: 3+)

### Retention
- D7 retention (target: 55%)
- D30 retention (target: 35%)
- W4 churn rate of users who never claimed a benefit vs. who did (this gap is the activation thesis)

### Reliability
- Crash-free session rate (target: 99.7%+)
- Notification delivery success rate (vs. scheduled count)
- Location-recommendation false-positive rate (user dismisses without tap, target: <60% — high inherent because banners can be glanced at)

### Catalog quality (when remote)
- % of user's cards that resolve to a catalog entry
- Catalog freshness SLO: benefits updated within 7 days of issuer announcement

---

## 10. Risks & Tradeoffs

### Product risks
- **Manual-claim drop-off.** Users forget to mark benefits as used. Mitigation: Apple Wallet transaction-tap suggestions, email-receipt parsing (V2+, opt-in), or accept that this is the privacy tradeoff.
- **Location feature triggers permission anxiety.** Pushy `always` request will tank ratings. Mitigation: lazy escalation (covered above).
- **Catalog accuracy is existential.** Outdated benefit data destroys trust faster than missing features. Mitigation: remote catalog + crowdsourced corrections + a clearly versioned changelog.
- **"Just another card tracker" perception.** Differentiation must be loud: privacy-first + location-aware. Marketing needs to lead with both.

### Technical debt risks
- **No SwiftData migration plan.** First model change is a ticking bomb. **P0 to fix before V2.**
- **Two `CardDataManager` instances.** Will produce visible state drift bugs. Easy fix.
- **Print-based logging.** Blocks data-driven iteration.
- **No tests.** Zero unit / UI tests in repo. The period math (`isCompleted`, `togglePeriod`, `currentPeriodInfo`) is exactly the kind of date logic that breaks silently — needs unit tests **before** V1.0.
- **Notification scheduling is missing despite README claims.** This is a credibility risk in the App Store listing.

### Scaling risks
- **MKLocalSearch rate limits** are not documented but exist. If recommendation usage spikes, requests will be throttled per device. Mitigation: tighter debouncing, cache POI results within cooldown radius.
- **Catalog growth.** 80+ cards × ~10 benefits each = 800+ benefit records bundled. JSON parsing on cold start will become noticeable. Move to lazy/per-issuer fetch.
- **iCloud sync conflict resolution** with `claimedPeriods` arrays will need explicit merge logic — append-only set semantics are safest.

### Suggested mitigations summary
| Risk | Mitigation | Priority |
|---|---|---|
| Catalog staleness | Remote catalog + ETag caching | P0 |
| Permission denial | Lazy permission escalation | P0 |
| Notification gap | Implement `UNCalendarNotificationTrigger` per benefit | P0 |
| State drift | Single shared `CardDataManager` | P0 |
| Schema breakage | `VersionedSchema` + migration plan | P0 |
| Untested date logic | Unit tests for period math | P0 |

---

## 11. Roadmap

### MVP — Ship-blockers (4–6 weeks)
1. Onboarding flow (3 screens + permission ladder)
2. Real benefit-expiration push notifications via `UNCalendarNotificationTrigger`
3. Reminders: extend window from "this month" to next 60 days
4. Edit existing card (currently a TODO)
5. Custom card editor with benefits and cashback categories
6. Settings: notification toggle + advance-days slider, location permission status, currency placeholder, points-valuation overrides, reset wallet
7. Single shared `CardDataManager` (refactor)
8. SwiftData `VersionedSchema` + migration plan
9. Unit tests for `Benefit.togglePeriod`, `BenefitTracker.currentPeriodInfo`, `PlaceRecommendationManager.bestCard`
10. App Privacy manifest + lazy permission escalation
11. Empty/error/permission-denied states polished
12. Replace `print()` with OSLog + analytics SDK

### V2 — Meaningful expansion (Q+1)
1. Remote, versioned catalog (Worker + R2 / Firebase)
2. iCloud (CloudKit) sync
3. Home Screen widget — "next expiring benefit" (small + medium)
4. Real Analytics tab — fee ROI per card, value extracted vs. potential, trend chart
5. Annual-fee renewal warning (30 days out, with ROI summary + product-change suggestions)
6. Off-location category-based card lookup
7. Crowdsourced catalog corrections (user-submitted, moderated)
8. Watch app + complication

### Future Vision (12+ months)
1. Apple Wallet pass deep-link integration ("Tap card to pay" handoff)
2. Email-receipt OCR (opt-in, on-device) for automatic benefit reconciliation
3. Live Activity that surfaces during dwell at a known merchant
4. Spending-goal tracker with multi-card spend optimization (Amex MR + Chase UR portfolio view)
5. Shared household wallet
6. International issuer catalog (UK, Canada to start — strong points-and-miles communities)
7. Optional iCloud-encrypted bank-aware mode for the segment willing to trade privacy for automation
8. Web companion (read-only) for travelers checking from a desktop

---

## 12. Open Questions

1. **Monetization.** Free + subscription? Free + one-time unlock? Catalog-only paid? Today there is no monetization — that's fine for V1, but the team should align on intent before D30 retention is measured (it changes the user contract).
2. **Card affiliate links.** "Apply for this card" links are the obvious revenue path, but compromise the trust posture. Decision needed.
3. **Catalog sourcing.** Maintained internally? Crowdsourced + moderated? Licensed (e.g., from Bankrate or CardRatings)? Affects cost, freshness, and legal exposure.
4. **Points valuation.** Default cents-per-point matrix — who maintains it, how often is it updated?
5. **Multi-account spending modeling.** When a user has both Amex Gold (4x dining) and Chase Sapphire Reserve (3x dining), should we recommend based on category point value or transferable-partners potential? This is a core "how smart is the recommender" question.
6. **Receipt of missed benefits.** When a user opens the app for the first time mid-year, should we backfill claimed periods or let them opt in per period?
7. **Privacy-mode marketing.** How loudly do we differentiate against Plaid-aggregator competitors without picking a public fight?
8. **Apple Wallet integration model.** Is deep-linking to a specific wallet card technically viable in iOS 17+? PoC needed.

---

## 13. Brutal PM Critique

### What feels weak
- **No onboarding.** The single biggest activation killer. Empty state is not an introduction.
- **Notifications are fictional.** README and product positioning depend on push reminders that aren't implemented. Either ship them or stop claiming them.
- **"Analytics" is a misnomer.** The current tab is a static lookup. Real analytics (ROI, value-extracted, trend) is the killer feature for the Sarah persona and isn't there.
- **Permission asks are aggressive.** Always-on location request on first launch will tank App Store ratings.
- **Custom-card flow is half-done.** Telling the user "you can add benefits later" with no UI to do so is a broken promise.
- **Reminder window too narrow.** Quarterly benefits are invisible until the last month — they need to be visible from day 1 of the period.

### What's overbuilt
- **12 issuer color tiles with bespoke styling.** Beautiful, but the ROI is low. Generic logos via remote catalog would be cleaner and update automatically.
- **1.8s splash sleep.** Pure delay. Cut it.
- **Issuer-specific gradient micro-styling.** Won't survive a brand refresh and adds maintenance burden.

### What's underbuilt
- Onboarding, notifications, custom-card editor, edit-card, real analytics, settings, error states, tests, observability, schema migration, remote catalog. That's a lot — and it's the difference between a polished demo and a shippable v1.

### What should be cut from V1
- Quadrennial reset period (almost no real-world benefit uses this — Amex Platinum's Global Entry credit being the rare exception). Defer until a real example forces the design.
- Issuer color tiles — replace with generic styling and a logo URL field on the catalog.
- The Analytics tab in its current form. Either delete or rebuild — don't ship a tab that doesn't deliver on the name.

### What should be prioritized
1. **Onboarding + permission ladder.** Highest leverage on every downstream metric.
2. **Real benefit notifications.** Closes the credibility gap between the listing and the app.
3. **Reminder window expansion.** Makes the Reminders tab useful all month, not just on the 28th.
4. **Custom-card editor + edit existing card.** Closes obvious functional holes.
5. **Remote catalog.** Without this, the product decays in production.

---

## 14. Engineering Handoff — Phased Implementation

### Phase 1 — "Ship What's Promised" (Weeks 1–4)
**Goal:** make the app match its own marketing.

- Implement `UNCalendarNotificationTrigger` scheduling per benefit per period, idempotent re-arming on app open, claim, and rollover.
- Expand `BenefitTracker` window from "ends this month" to next 60 days; verify urgency thresholds still feel right.
- Build onboarding (3 screens + lazy permission ladder).
- Wire `CardDataManager` as a single shared `@EnvironmentObject` from `PerqApp`.
- Replace all `print()` with OSLog + a privacy-friendly analytics SDK; instrument the events listed in §7.
- Settings v1: notification toggle + advance days, location status row, reset wallet.
- Cut splash sleep to 0.6s.
- Unit tests for period math and best-card selection.

**Sequencing rationale:** these are the changes that prevent us from being credibly criticized. Notifications and onboarding are the two highest-impact metrics movers. Single-source-of-truth and analytics are prerequisites for everything that follows.

### Phase 2 — "Earn Trust at Scale" (Weeks 5–10)
**Goal:** the product holds up as the catalog ages and users multiply devices.

- Remote catalog (versioned JSON behind a CDN, ETag-cached, bundled fallback).
- SwiftData `VersionedSchema` + migration policy (do this **before** any model change ships).
- iCloud (CloudKit) sync for `CreditCard`, `Benefit`, `CashbackCategory`. Conflict policy: claimedPeriods is a set-union; usedAmount takes max.
- Edit-card flow.
- Custom-card benefit/cashback editor.
- Real Analytics tab: fee ROI, value extracted vs. potential, monthly trend.
- Annual-fee renewal warning + ROI summary 30 days before `renewalDate`.
- Off-location category lookup ("I'm shopping at Amazon — which card?").
- Points-valuation override Settings.

**Sequencing rationale:** catalog freshness compounds — every week without it, more user data is wrong. iCloud sync cannot land before schema migration is in place or we will brick existing installs. Analytics depends on stable schema and correct claim data.

### Phase 3 — "Become the Default" (Weeks 11+)
**Goal:** make Perq the app premium cardholders open daily.

- Home Screen widget (small + medium), Lock Screen widget, Live Activity for dwell.
- Apple Watch app + complication.
- Apple Wallet pass deep-link PoC; if viable, ship as the marquee differentiator.
- Crowdsourced catalog corrections (user proposes change → moderated update).
- CSV/PDF export.
- Spending-goal tracker.
- Begin Android scoping (only if iOS retention proves the thesis).

**Sequencing rationale:** these are habit-forming surfaces that only make sense once core data is reliable, syncing, and accurately scheduled. Shipping a widget over an unreliable benefit calendar would amplify bugs onto the Home Screen.

---

**Closing note.** The codebase is unusually mature for a personal project — the location-recommendation engine alone (dwell + cooldown + accuracy + speed filtering) is more thoughtful than what most shipped apps in this category do. The biggest gap is not technical; it's the distance between the product's marketing claims and what's actually wired up. Phase 1 is almost entirely about closing that gap. Do that, and Perq has a real shot.
