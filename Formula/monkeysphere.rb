class Monkeysphere < Formula
  desc "Use the OpenPGP web of trust to verify ssh connections"
  homepage "http://web.monkeysphere.info/"
  url "https://deb.debian.org/debian/pool/main/m/monkeysphere/monkeysphere_0.44.orig.tar.gz"
  sha256 "6ac6979fa1a4a0332cbea39e408b9f981452d092ff2b14ed3549be94918707aa"
  license "GPL-3.0-or-later"
  revision 2
  head "git://git.monkeysphere.info/monkeysphere"

  livecheck do
    url "https://deb.debian.org/debian/pool/main/m/monkeysphere/"
    regex(/href=.*?monkeysphere.?v?(\d+(?:\.\d+)+)(?:\.orig)?\.t/i)
  end

  bottle do
    cellar :any
    sha256 "b81913712d547ed0cafbb84478af579142a7409a8c15a2349c8e0eadba5693eb" => :catalina
    sha256 "d5c8badc7a3296cd5150f3520a0abf61aa4a683a43d121961b412ff619aaa4d1" => :mojave
    sha256 "5928a7723f50b5ce5c505571570a6bb82823f6faf0133ab2f9b0f2757a9b68fc" => :high_sierra
    sha256 "f1bbf185764cd974016f73e4a6d037cec60a83b57c3a3314797aa8aa60edf1bb" => :sierra
  end

  depends_on "gnu-sed" => :build
  depends_on "bash" # Apple's BASH 3.2 is insufficient, BASH 4.X features are used
  depends_on "coreutils"
  depends_on "findutils" # GNU extensions are used with find
  depends_on "gnupg"
  depends_on "libassuan"
  depends_on "libgcrypt"
  depends_on "libgpg-error"
  depends_on "liblockfile"
  depends_on "openssl@1.1"

  resource "Crypt::OpenSSL::Bignum" do
    url "https://cpan.metacpan.org/authors/id/K/KM/KMX/Crypt-OpenSSL-Bignum-0.09.tar.gz"
    sha256 "234e72fb8396d45527e6fd45e43759c5c3f3a208cf8f29e6a22161a996fd42dc"
  end

  def install
    ENV.prepend_path "PATH", Formula["gnu-sed"].libexec/"gnubin"
    ENV.prepend_create_path "PERL5LIB", libexec/"lib/perl5"

    resource("Crypt::OpenSSL::Bignum").stage do
      system "perl", "Makefile.PL", "INSTALL_BASE=#{libexec}"
      system "make", "install"
    end

    ENV["PREFIX"] = prefix
    ENV["ETCPREFIX"] = prefix
    system "make", "install"

    # This software expects to be installed in a very specific, unusual way.
    # Consequently, this is a bit of a naughty hack but the least worst option.
    inreplace pkgshare/"keytrans", "#!/usr/bin/perl -T",
                                   "#!/usr/bin/perl -T -I#{libexec}/lib/perl5"

    # find is used with GNU only permissions mode
    inreplace pkgshare/"common", "$(find ",
                                 "$(gfind "
    # use liblockfile
    inreplace pkgshare/"common", "lockfile-create",
                                 "dotlockfile"
    inreplace pkgshare/"common", "lockfile-touch",
                                 "dotlockfile -T"
    inreplace pkgshare/"common", "lockfile-remove",
                                 "dotlockfile -u"

    # Needs BASH 4.0 or later, Apple's BASH 3.2 is insufficient
    inreplace bin/"monkeysphere", "#!/usr/bin/env bash",
                                  "#!#{Formula["bash"].opt_bin}/bash"
    inreplace sbin/"monkeysphere-host", "#!/usr/bin/env bash",
                                        "#!#{Formula["bash"].opt_bin}/bash"
    inreplace sbin/"monkeysphere-authentication", "#!/usr/bin/env bash",
                                                  "#!#{Formula["bash"].opt_bin}/bash"
  end

  def caveats
    <<~EOS
      This formula installs BASH as a dependency because Monkeysphere requires a newer 
      version of BASH than what Apple provides. Login shells will still use Apple's 
      version of BASH, /usr/bin/bash, but invocations of bash which rely on the PATH will
      use the Homebrew installed BASH, e.g. '/usr/bin/env bash' will execute the Homebrew 
      bash executable.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/monkeysphere v")
    # This just checks it finds the vendored Perl resource.
    assert_match "We need at least", pipe_output("#{bin}/openpgp2pem --help 2>&1")
  end
end
