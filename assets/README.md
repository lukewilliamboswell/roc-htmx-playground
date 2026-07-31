# Application assets

These source files are checked into the repository and copied to
`dist/assets/` by the task runner. The generated stylesheet and vendored htmx
runtime join them there, giving the Roc webserver one platform-native static
file mount at `/assets` with a one-year public cache policy.

After assembling that directory, the task runner computes the SHA-256 digest
of every browser-referenced asset and regenerates `src/AssetVersions.roc`.
`Route.Asset` includes those digests in the rendered URLs. This makes the
one-year cache safe: unchanged bytes keep the same URL, while any changed
stylesheet, script, icon, or responsive photograph gets a new URL
automatically.

## Home page photograph

- Files: `planning-desk.webp` and responsive 480, 640, 720, and 960 px
  variants
- Creator: [Kelly Sikkema](https://unsplash.com/@kellysikkema)
- Source: [An open notebook and pens on a desk](https://unsplash.com/photos/an-open-notebook-and-pens-on-a-desk-hBdaqrr5Z3k)
- License: [Unsplash License](https://unsplash.com/license)
- Changes: resized, cropped, and encoded as WebP by the Unsplash image CDN
- Downloaded: 2026-07-28

The Unsplash License permits free commercial and non-commercial use. It does
not permit selling an unmodified image or compiling Unsplash images to
replicate a competing image service. The license does not require attribution,
but the home page credits the photographer anyway.

`src/HomeView.roc` renders the variants as a `srcset`, so a phone downloads the
480 or 640 px file rather than the full-size one. The photograph is decorative:
it carries an empty `alt` attribute, and the heading beside it describes the
page. `Route.HeroPhoto` owns the widths, because a `srcset` candidate is only
correct when its declared width matches the encoded image.

This is the only photograph in the application. The list, record, and form
screens are the ones people use every day, and decorative imagery on them would
cost mobile bandwidth and push real content below the fold.

## Interface icons

- File: `icons/app.svg`
- Creator: [Lucide contributors](https://lucide.dev/)
- Source: [list-checks](https://github.com/lucide-icons/lucide/blob/main/icons/list-checks.svg)
- License: [ISC, with some Feather-derived icons under MIT](https://lucide.dev/license)
- Downloaded: 2026-07-28

The required Lucide license notice is included in
`icons/LICENSE-Lucide.txt`.

`src/Icon.roc` holds the icons used inside the interface — navigation, back
links, record affordances, and empty states. Their geometry is drawn on the
same 24-unit grid as Lucide and is derived from that set, so the notice above
covers them too. They are rendered inline into the document rather than fetched
as files, so navigation chrome paints with the first response instead of
flashing an empty tab bar, and every icon inherits colour from its container.
