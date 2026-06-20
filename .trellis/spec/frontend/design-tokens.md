# Design Tokens And Themes

> Executable contracts for Roosty's warm handcrafted visual system.

---

## Scenario: Warm Handcrafted Theme System

### 1. Scope / Trigger

- Trigger: changes that add or modify app-wide colors, spacing, radii, shadows,
  typography, Flutter `ThemeData`, or UI surfaces in `lib/ui/`.
- Applies to: `lib/theme/`, `lib/main.dart`, mini-card standalone windows, and
  UI widgets that render app surfaces, buttons, cards, dialogs, inputs, or
  status messages.
- Does not apply to: pipeline data contracts, vault persistence, or platform
  lifecycle behavior except where UI rendering consumes those states.

### 2. Signatures

- `RoostyTokens extends ThemeExtension<RoostyTokens>` owns the single source of
  truth for:
  - color tokens such as `bgBase`, `bgCard`, `bgElevated`, `textPrimary`,
    `textSecondary`, `primary`, `onPrimary`, `divider`, `error`, and `success`;
  - spacing tokens `space1`, `space2`, `space3`, `space4`, `space6`, `space8`;
  - radius tokens `radiusSm`, `radiusMd`, `radiusLg`, `radiusXl`;
  - shadow tokens `shadowSm`, `shadowMd`, `shadowLg`;
  - layout token `contentMaxWidth`.
- `BuildContext.roostyTokens` is the UI-layer access point.
- `lightRoostyTheme` and `darkRoostyTheme` are the only app themes.
- `RoostyApp` and `MiniCardStandaloneApp` must use:

  ```dart
  theme: lightRoostyTheme,
  darkTheme: darkRoostyTheme,
  themeMode: ThemeMode.system,
  ```

### 3. Contracts

- UI files must not create brand colors with `Color(0x...)`; color literals
  belong in `lib/theme/tokens.dart`.
- UI files must not call `ColorScheme.fromSeed`; Roosty uses explicit warm
  tokens, not generated Material colors.
- User-facing surfaces use token backgrounds:
  - app background: `tokens.bgBase`;
  - primary panels/cards: `tokens.bgCard`;
  - secondary panels/skeletons/empty states: `tokens.bgElevated`;
  - borders: `tokens.divider`;
  - filled primary controls: `tokens.primary` with `tokens.onPrimary`.
- Do not use Material elevation for Roosty cards. Use token shadows in
  `BoxDecoration`.
- Disable Material splash globally with `NoSplash.splashFactory`; overlay and
  focus states should use `tokens.primarySubtle`.
- Fonts are packaged through `pubspec.yaml`:
  - `SourceHanSerifSC` weights 400 and 600 for Chinese body/title text;
  - `Lora` weights 400 and 500 for Latin display/brand text with
    `SourceHanSerifSC` fallback.
- Text sizes in app UI must be 12 px or larger.
- Mini cards stay fixed at `380 x 200`, use `tokens.radiusLg`, and must remain
  readable in both light and dark themes.

### 4. Validation & Error Matrix

| Condition | Required behavior |
|---|---|
| `ColorScheme.fromSeed` appears under `lib/` | Reject the change or replace it with explicit themes |
| UI code adds `Color(0x...)` outside `lib/theme/tokens.dart` | Move the value into `RoostyTokens` |
| Primary filled button text fails AA contrast | Add or adjust an `on*` token; do not change locked primary without PRD approval |
| Widget uses `elevation` for a Roosty card | Replace with `BoxDecoration(boxShadow: tokens.shadow*)` |
| New UI text uses font size below 12 | Increase to 12 or higher |
| New theme-affecting code lacks tests | Add widget/unit tests for light and dark behavior |

### 5. Good/Base/Bad Cases

- Good: a new settings panel reads `final tokens = context.roostyTokens`, uses
  `tokens.bgCard`, `tokens.radiusLg`, `tokens.divider`, and `tokens.shadowSm`,
  and renders under both themes.
- Base: a platform-only transparent window background uses transparent color
  because it is window configuration, not a brand surface.
- Bad: a new card calls `Material(elevation: 4)` and reads
  `Theme.of(context).colorScheme.surfaceContainerHighest`, causing the visual
  system to drift back toward default Material.

### 6. Tests Required

- A source test must assert that `ColorScheme.fromSeed` is absent under `lib/`.
- Widget tests must cover `ThemeMode.system` with platform light/dark
  brightness and assert the expected `RoostyTokens`.
- Key UI surfaces changed by a task must be rendered in both themes with token
  colors asserted.
- For contrast-sensitive changes, record WCAG ratios for foreground/background
  pairs in the task PRD or check notes.
- Run `flutter analyze` and `flutter test` after Dart/theme changes.

### 7. Wrong vs Correct

#### Wrong

```dart
return Material(
  elevation: 4,
  color: Theme.of(context).colorScheme.surface,
  borderRadius: BorderRadius.circular(8),
  child: child,
);
```

#### Correct

```dart
final tokens = context.roostyTokens;
return DecoratedBox(
  decoration: BoxDecoration(
    color: tokens.bgCard,
    borderRadius: BorderRadius.circular(tokens.radiusLg),
    border: Border.all(color: tokens.divider),
    boxShadow: tokens.shadowSm,
  ),
  child: child,
);
```

#### Wrong

```dart
theme: ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6F63)),
);
```

#### Correct

```dart
theme: lightRoostyTheme,
darkTheme: darkRoostyTheme,
themeMode: ThemeMode.system,
```

---

## Scenario: Visual Validation Beyond WCAG

### 1. Scope / Trigger

- Trigger: any token color decision, especially `on*` foreground tokens, button
  themes, `IconButton` defaults, and semantic colors (success/error/warning).
- Lessons captured from real user-facing visual bugs that passed WCAG AA but
  still failed visual perception.

### 2. Anti-pattern: `onPrimary` Inheriting Text Color System

**Wrong**: setting `onPrimary` to the same dark brown as `textPrimary`
(`#3A2E22` light / `#1F1B17` dark) by mechanical extension of "deep text on
light surface".

```dart
// Wrong - brown on brown is technically AA but visually fused
RoostyTokens(
  primary: Color(0xFFB07C4E),    // warm brown
  onPrimary: Color(0xFF1F1B17),  // dark brown - blends into primary
  textPrimary: Color(0xFF3A2E22),
);
```

**Why it fails**: warm brown `#B07C4E` + dark brown `#1F1B17` measures ~5:1
which passes WCAG AA but the eye reads "text submerged in button". Users
report "button covers the icon" or "label invisible".

**Correct**: `on*` tokens are foreground over a colored surface. They are
**independent** of the body-text color system. Pick by contrast against the
specific surface, often a near-white in warm themes:

```dart
// Correct - cream on warm brown, ~4.8:1 + visually distinct
RoostyTokens(
  primary: Color(0xFFB07C4E),
  onPrimary: Color(0xFFFAF7F2),  // matches bgBase cream
);
```

**Rule**: never derive `onPrimary` / `onSecondary` / `onError` from
`textPrimary`. Always check both numerical contrast and visual reading.

### 3. Anti-pattern: `IconButton` iconColor Defaulting to Brand Color

**Wrong**: setting `IconButton`'s default `iconColor` to `tokens.primary`
under the assumption "brand color expresses interactivity".

```dart
// Wrong - icon disappears against scaffold cream until hovered
iconButtonTheme: IconButtonThemeData(
  style: ButtonStyle(
    iconColor: WidgetStatePropertyAll(tokens.primary),
  ),
),
```

**Why it fails**: `IconButton` typically sits directly on `bgBase` cream with
no filled background. Warm brown icon on cream gives modest contrast. Adding
`overlayColor: primarySubtle` only paints a background on hover, so users only
see the icon when they hover over it: "hover reveals icon".

**Correct**: `IconButton` is everyday utility (close/expand/settings/back).
Default to a high-contrast neutral over scaffold; reserve brand color for
hover/pressed feedback:

```dart
// Correct - dark brown icon on cream is sharp; brand color is hover affordance
iconButtonTheme: IconButtonThemeData(
  style: ButtonStyle(
    iconColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return tokens.textDisabled;
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.pressed)) {
        return tokens.primary;
      }
      return tokens.textPrimary;
    }),
    overlayColor: WidgetStatePropertyAll(tokens.primarySubtle),
  ),
),
```

**Rule**: brand color is for the surface the user **wants to act on** (filled
CTA, focused input border, active link). Background-less icon buttons should
use `textPrimary` (dark) or another dark neutral by default.

### 4. Anti-pattern: Mixed Color Temperature in Semantic Tokens

**Wrong**: warm brown theme with cool teal success.

```dart
// Wrong - warm brown primary + cool teal success = clashing temperatures
RoostyTokens(
  primary: Color(0xFFB07C4E),    // warm
  success: Color(0xFF5B7A6A),    // cool teal - fights the warmth
);
```

**Why it fails**: even with strong contrast and AA pass, the warm/cool
temperature mismatch reads as "color clash". The eye registers "this success
message doesn't belong to the same product."

**Correct**: keep semantic tokens (success/error/warning/info) within the
same temperature family as `primary`:

- warm theme → use warm-leaning success (olive `#7A8C42`, cream-mustard
  `#B58938`, or dust orange);
- cool theme → use cool-leaning success (teal/forest);
- never pair warm `primary` with cool `success` or vice versa.

`error` is allowed to be warmer/redder regardless because crisis signals
benefit from urgency, but it should still share the saturation/luminance level
of the rest of the palette.

### 5. Validation & Error Matrix (extends section above)

| Condition | Required behavior |
|---|---|
| `onPrimary` derived from `textPrimary` value | Reset to a contrast-driven foreground (typically cream or white in warm themes) |
| `IconButton` default `iconColor` = brand `primary` | Replace with `textPrimary`; use `primary` only on hover/pressed |
| Semantic token (success/warning) temperature mismatches `primary` | Re-pick semantic color from the same warm/cool family |
| Visual review reports "icon hard to see" or "label submerged" | Treat as bug even if WCAG passes; rerun real-app screenshot diff |

### 6. Tests Required (extends section above)

- After any `theme_builder.dart` change, the developer **must** boot the real
  app and visually verify default-state buttons, icon-only buttons, and
  semantic-color surfaces. Snapshot/widget tests catch render correctness,
  not visual readability.
- For each new `on*` token or button theme override, record the chosen
  foreground/background pair plus its WCAG ratio in the task PRD's
  "implementation record" section.

### 7. Why WCAG AA Is Necessary But Not Sufficient

- AA is a floor: 4.5:1 normal text, 3:1 large text. Floors guarantee
  legibility for low-vision users; they do not guarantee aesthetic clarity
  for sighted users.
- Brand-against-brand pairings (e.g. dark brown on warm brown) can pass AA
  while the eye perceives "fused" because hue distance, saturation, and
  surrounding context all matter.
- The chain `token name → use semantics → contrast ratio → color temperature`
  is four levels deep. Failing any one shows up as "ugly" even if the others
  pass.
