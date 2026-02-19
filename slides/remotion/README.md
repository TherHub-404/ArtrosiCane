# ArtrosiCane Remotion Visuals

Visual e animazioni 16:9 (1920x1080) pensate per slide pitch/demo.

## Contenuto

- `ArtrosiSlidesShowcase` (circa 8.6s):
  - Intro logo reveal
  - Feature cards animate
  - Outcome / value proposition
- `ArtrosiLogoReveal` (3s): opener pulito con logo + payoff

## Setup

```bash
cd slides/remotion
npm install
npm run start
```

## Render

```bash
cd slides/remotion
npm run render:showcase
npm run render:logo
npm run render:gif:flow
npm run render:gif:iphone
npm run render:gif:journey
```

Output in `slides/remotion/out/`.

## Personalizzazione rapida

- Palette: `slides/remotion/src/Brand.ts`
- Copy intro: `slides/remotion/src/visuals/LogoReveal.tsx`
- Cards feature: `slides/remotion/src/visuals/FeatureStrip.tsx`
- Messaggio finale: `slides/remotion/src/visuals/OutcomeScene.tsx`

## Note

- Il logo viene caricato da `public/ArtrosiCane-Logo.png` tramite `staticFile()`.
- Le animazioni sono frame-based (`useCurrentFrame`) e non usano CSS animations.
