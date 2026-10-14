# homebrew-adium (draft)

A Homebrew tap that builds [Adium](https://github.com/KnutMann/adium) from source.
It answers [KnutMann/adium#9](https://github.com/KnutMann/adium/issues/9).

**This is a draft to hand over.** KnutMann maintains Adium, so the tap belongs with him,
e.g. as `KnutMann/homebrew-adium`. This repository will not be maintained on its own.

## Install

```sh
brew tap iilonmasc/adium
brew trust --formula iilonmasc/adium/adium   # Homebrew 7 loads third-party formulae only once trusted
brew install adium
ln -sf "$(brew --prefix)/var/adium/Adium.app" ~/Applications/Adium.app
```

Requirements: Apple Silicon and a full Xcode (the Command Line Tools alone are not enough).

## How it works

- The formula builds a pinned revision of `KnutMann/adium` the same way `./install.sh --build-only` does.
  It fetches the WebRTC framework and picomemo as pinned resources, and it runs
  `Utilities/verify-purple-plugins.sh` before and after the build.
- The app is signed ad hoc. A bundle built on the machine has no quarantine attribute,
  so Gatekeeper lets it start without notarisation and without a paid Apple Developer account.
- Homebrew rewrites the install names of every Mach-O file inside a keg and re-signs each
  file on its own, which breaks the bundle's signature. So the keg keeps the verified bundle
  as a zip, and `post_install_steps` unpacks it to `$(brew --prefix)/var/adium/Adium.app`,
  which Homebrew leaves alone.
- `brew uninstall adium` leaves `$(brew --prefix)/var/adium` behind. Remove it by hand.

## Caveat: OpenSSL

picomemo is compiled against the headers of Homebrew's `openssl@3`, but it links the
`libcrypto.3.dylib` bundled with Adium. Today both are 3.5.9, and every OpenSSL symbol
the app needs is exported by the bundled copy. If Homebrew's `openssl@3` moves past the
bundled release, that check has to be repeated, or the formula has to pin a matching branch.

## Tested

- Apple M5 Pro, macOS 27.0.1, Xcode 27.0, Homebrew 7.0.9
- `brew install --build-from-source` took about 1.5 minutes
- `brew audit --strict`, `brew style` and `brew test` pass
- Linked to `~/Applications` as shown above, the app starts without a Gatekeeper prompt
  and loads all of its protocol plug-ins
