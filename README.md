# homebrew-adium

A Homebrew tap that builds [Adium](https://github.com/KnutMann/adium) from source
on Apple Silicon. It exists because there is no signed download yet
([KnutMann/adium#9](https://github.com/KnutMann/adium/issues/9)): a bundle built
on your own machine carries no quarantine attribute, so Gatekeeper lets it start
without notarisation and without anybody holding a paid Apple Developer account.

## Install

```sh
brew tap KnutMann/adium
brew trust --formula KnutMann/adium/adium   # Homebrew 7 loads third-party formulae only once trusted
brew install KnutMann/adium/adium
ln -sf "$(brew --prefix)/var/adium/Adium.app" ~/Applications/Adium.app
```

Spell the formula out. Homebrew's own tap has a cask called `adium` too, and
that one is the last Intel release, 1.5.10.4, which runs on Apple Silicon only
through Rosetta and connects to nothing this fork added.

Requirements: Apple Silicon, macOS 13 or later, and a full Xcode 16 or newer.
The Command Line Tools alone cannot build an Xcode project. The build takes a
few minutes.

## Update

```sh
brew update && brew upgrade KnutMann/adium/adium
```

The formula pins one revision of the repository, and a new pin is a new
version, so `brew upgrade` sees it. `brew install --HEAD KnutMann/adium/adium`
builds the tip of `master` instead.

## How it works

- The formula builds a pinned revision of `KnutMann/adium` the same way
  `./install.sh --build-only` does. It fetches the WebRTC framework and picomemo
  as pinned resources and runs `Utilities/verify-purple-plugins.sh` before and
  after the build, so a protocol plug-in that does not register with the bundled
  libpurple fails the install rather than the first connection.
- Nothing in the build comes from Homebrew. The OpenSSL headers that picomemo and
  the OMEMO media code compile against are checked into the repository beside the
  libcrypto they link.
- The app is signed ad hoc. Homebrew rewrites the install names of every Mach-O
  file inside a keg and re-signs each file on its own, which would break the
  bundle's signature, so the keg keeps the verified bundle as a zip and
  `post_install_steps` unpacks it to `$(brew --prefix)/var/adium/Adium.app`, which
  Homebrew leaves alone.
- `brew uninstall adium` leaves `$(brew --prefix)/var/adium` behind. Remove it by
  hand.

## Origin

Drafted by Tim Otlik ([@iilonmasc](https://github.com/iilonmasc)) in October 2026
as an answer to issue 9, and handed over to live beside the application. Thank you.
