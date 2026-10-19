# Builds Adium from source, the way ./install.sh --build-only does.
#
# A formula may not write to /Applications, and a cask would need a notarised
# download. Built here, the bundle carries no quarantine attribute, so the ad
# hoc signature xcodebuild gives it is enough for Gatekeeper, as long as
# nothing touches the bundle afterwards. Homebrew does touch it: every Mach-O
# file in a keg has its install names rewritten to keg paths and is re-signed
# on its own, which breaks the seal of the bundle around it. So the keg holds
# the verified bundle as an archive, and post_install unpacks it into var/,
# which Homebrew does not relocate.
class Adium < Formula
  desc "Instant messaging application for macOS, built from source"
  homepage "https://github.com/KnutMann/adium"
  url "https://github.com/KnutMann/adium.git",
      revision: "3ad6c109cc53a84708d57e4a7fe91d43bde864a0"
  # The application's own version, then the date of the pinned revision, so
  # that every new pin compares greater than the one before it and brew
  # upgrade notices.
  version "1.8.0.20261019"
  license "GPL-2.0-or-later"
  head "https://github.com/KnutMann/adium.git", branch: "master"

  depends_on xcode: ["16.0", :build]
  # The frameworks and protocol plug-ins checked into the repository are arm64
  # only, and the application is built for macOS 13.
  depends_on arch: :arm64
  depends_on macos: :ventura

  # Pinned as in Dependencies/webrtc/fetch-webrtc.sh.
  resource "webrtc" do
    url "https://github.com/stasel/WebRTC/releases/download/153.0.0/WebRTC-M153.xcframework.zip"
    sha256 "3e3a8946f27510133e3feed04d05fa23505bbe366e977620503bfc7986c2b78f"
  end

  # Pinned as in Dependencies/picomemo/fetch-picomemo.sh.
  resource "picomemo" do
    url "https://github.com/mierenhoop/picomemo.git",
        revision: "3ad6c109cc53a84708d57e4a7fe91d43bde864a0"
  end

  def app_archive
    libexec/"Adium.app.zip"
  end

  def app
    var/"adium/Adium.app"
  end

  def install
    # What Dependencies/fetch.sh would download, staged where it would put it.
    # The submodule MMTabBarView comes with the git checkout. Homebrew unpacks
    # the archive's single top-level directory away.
    (buildpath/"Dependencies/webrtc/WebRTC.xcframework").install resource("webrtc")
    (buildpath/"Dependencies/picomemo/picomemo").install resource("picomemo")

    # Through the environment, as fetch-picomemo.sh does: on the command line
    # CFLAGS would replace the include paths the Makefile appends to it. The
    # OpenSSL headers are the repository's own, checked in beside the libcrypto
    # the application links, so nothing in this build comes from Homebrew.
    cd "Dependencies/picomemo/picomemo" do
      with_env(DRIVERS: "c25519.c openssl.c",
               CFLAGS:  "-O2 -mmacosx-version-min=13.0 -I#{buildpath}/Frameworks/openssl/include") do
        system "make", "o/libpicomemo.a"
      end
    end

    system "Utilities/verify-purple-plugins.sh"

    xcodebuild "-project", "Adium.xcodeproj",
               "-scheme", "Adium - Release",
               "-destination", "platform=macOS,arch=arm64",
               "-derivedDataPath", buildpath/"DerivedData",
               "SYMROOT=#{buildpath}/build",
               "OBJROOT=#{buildpath}/build/Intermediates",
               "CODE_SIGN_IDENTITY=-", "CODE_SIGN_STYLE=Manual", "DEVELOPMENT_TEAM=",
               "build"

    built = buildpath/"build/Release/Adium.app"
    system "Utilities/verify-purple-plugins.sh", "--app", built
    system "codesign", "--verify", "--deep", "--strict", built
    libexec.mkpath
    system "ditto", "-c", "-k", "--keepParent", built, app_archive
  end

  post_install_steps do
    if_path_exists "adium/Adium.app", base: :var do
      remove "adium/Adium.app", base: :var, recursive: true
    end
    mkdir_p "adium", base: :var
    run "/usr/bin/ditto", args:           ["-x", "-k", "{{libexec}}/Adium.app.zip", "{{var}}/adium"],
                          writable_paths: ["adium"], writable_base: :var
  end

  def caveats
    <<~EOS
      Adium.app is unpacked to:
        #{app}
      To find it in Launchpad and Spotlight:
        ln -sf #{app} ~/Applications/Adium.app
      `brew uninstall adium` leaves #{app.dirname} behind; remove it by hand.
    EOS
  end

  test do
    assert_path_exists app/"Contents/MacOS/Adium"
    system "codesign", "--verify", "--deep", "--strict", app
  end
end
