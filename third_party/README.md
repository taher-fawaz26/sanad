# third_party/

## font_awesome_flutter (Pro, dynamic)

`font_awesome_flutter/` is a **configured local copy** of the
[font_awesome_flutter](https://pub.dev/packages/font_awesome_flutter) package
(v11.0.0), customized to support **Font Awesome Pro 7.3.1** and **dynamic
icon lookup by CSS class string** (`getIconFromCss` / `faIconNameMapping`).
This is the package's own supported customization mechanism (its
`util/configurator.sh` tool), not a source fork.

**This directory is intentionally vendored (tracked in git) in this PRIVATE
repository.** It embeds Font Awesome Pro OTF fonts and generated Dart, which
are proprietary assets tied to the project's paid Font Awesome Pro
subscription (trysanad.us account). Vendoring it makes the repo self-contained:
a clean checkout / CI runs `melos bootstrap` with no restore or regeneration
step. **Because these are licensed Pro assets, keep this repository private and
do not redistribute them or make the repo public.** The regeneration steps
below are retained only for bumping the Pro version.

Only runtime files are tracked. The configurator-only `lib/fonts/icons.json`
(~110 MB, not a declared asset), the stock `example/` app, and `.dart_tool/`
are git-ignored (see the root `.gitignore`).

Consumers reference it via `dependency_overrides` (see
`packages/design_system/pubspec.yaml`), never a normal `pubspec.yaml`
dependency, since it lives outside the melos `workspace:` list.

### Regenerating it

You need:
1. A Font Awesome Pro **Desktop** download (not the Web/Subsetter kit) —
   from the project's Font Awesome account, currently Pro **7.3.1**.
2. `fvm` set up per the repo's `.fvmrc` (Flutter 3.41.9).

Steps:

```bash
# 1. Copy the stock package (same version pinned in packages/design_system/pubspec.yaml)
#    from your local pub-cache (run `fvm flutter pub get` once in the repo first
#    if it isn't cached yet).
cp -R ~/.pub-cache/hosted/pub.dev/font_awesome_flutter-11.0.0 third_party/font_awesome_flutter
chmod -R u+w third_party/font_awesome_flutter

# 2. Drop in the Pro assets (rename spaces -> dashes)
FA=third_party/font_awesome_flutter
KIT=/path/to/fontawesome-pro-7.3.1-desktop   # wherever you extracted the Pro zip
rm -f "$FA"/lib/fonts/*.otf
for f in \
  "Font Awesome 7 Pro-Solid-900.otf" \
  "Font Awesome 7 Pro-Regular-400.otf" \
  "Font Awesome 7 Pro-Light-300.otf" \
  "Font Awesome 7 Pro-Thin-100.otf" \
  "Font Awesome 7 Brands-Regular-400.otf" \
  "Font Awesome 7 Sharp-Solid-900.otf" \
  "Font Awesome 7 Sharp-Regular-400.otf" \
  "Font Awesome 7 Sharp-Light-300.otf" \
  "Font Awesome 7 Sharp-Thin-100.otf"; do
  cp "$KIT/otfs/$f" "$FA/lib/fonts/${f// /-}"
done

# IMPORTANT: use metadata/icon-families.json, NOT metadata/icons.json.
# Only icon-families.json carries the `svgs.sharp` map the configurator
# needs to generate "sharp solid"/"sharp regular"/... mapping keys; the
# legacy icons.json has classic styles only (no sharp).
cp "$KIT/metadata/icon-families.json" "$FA/lib/fonts/icons.json"

# 3. Resolve the configurator's own dev dependencies, then run it
cd "$FA"
fvm flutter pub get
dart ./util/lib/main.dart --dynamic
cd -
```

Do **not** pass `--exclude` — we want every style the account's Pro tier
supports (solid, regular, light, thin, brands, and all 4 sharp weights).
Duotone / sharp-duotone are excluded automatically by the configurator
itself (unsupported in this Flutter package version) — do not add those
otfs.

Expected output: the configurator should report
`Found and enabled the following icon styles: brands, regular, solid, light, thin, sharpthin, sharplight, sharpregular, sharpsolid`.

### Why dynamic lookup needs a resolver, not the generated `getIconFromCss`

The generator's own `getIconFromCss` only recognizes legacy short CSS
tokens (`fas`, `far`, `fab`, `fal`, `fat`) and has no notion of `fa-sharp`.
It cannot parse the backend's actual contract (`"fa-solid fa-store"`,
`"fa-sharp fa-solid fa-house"`, etc.). The app's own resolver —
`packages/design_system/lib/src/icons/backend_icon_resolver.dart` — does its
own generic CSS parsing and looks up `faIconNameMapping` directly. See that
file's doc comment and `docs/features/` for the full design.

### Build flag

Dynamic-by-name lookup defeats Flutter's icon tree-shaking. Any release
build of `sanad_provider` must pass `--no-tree-shake-icons`.

### CI

No CI step is needed: this package is vendored (tracked in git), so a clean
checkout already contains it and `melos bootstrap` resolves the
`dependency_overrides` path directly. There is no restore/download step and no
release-asset mechanism.
