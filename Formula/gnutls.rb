class Gnutls < Formula
  desc "GNU Transport Layer Security (TLS) Library"
  homepage "https://gnutls.org/"
  url "https://www.gnupg.org/ftp/gcrypt/gnutls/v3.6/gnutls-3.6.14.tar.xz"
  mirror "https://www.mirrorservice.org/sites/ftp.gnupg.org/gcrypt/gnutls/v3.6/gnutls-3.6.14.tar.xz"
  sha256 "5630751adec7025b8ef955af4d141d00d252a985769f51b4059e5affa3d39d63"
  # license "LGPL-2.1-or-later AND GPL-3.0-only" - review syntax after resolving https://github.com/Homebrew/brew/pull/8260
  license "GPL-3.0-only"

  bottle do
    sha256 "ed76b5d22e195a797c2d01ab2f4a8e769a023b056b17e86f11cb6b9af200babe" => :catalina
    sha256 "d57c7537ca0565e8c8fdf13beb4b082548f87a0df2295469596f1cfe3067faae" => :mojave
    sha256 "2773c249c2a71f299261889185bda3950ed15150ff09529a71f88c30d68ff26f" => :high_sierra
  end

  depends_on "autoconf" => :build
  depends_on "automake" => :build
  depends_on "pkg-config" => :build
  depends_on "gmp"
  depends_on "guile"
  depends_on "libidn2"
  depends_on "libtasn1"
  depends_on "libunistring"
  depends_on "nettle"
  depends_on "p11-kit"
  depends_on "unbound"

  on_linux do
    depends_on "autogen" => :build
  end

  def install
    args = %W[
      --disable-dependency-tracking
      --disable-silent-rules
      --disable-static
      --prefix=#{prefix}
      --sysconfdir=#{etc}
      --with-default-trust-store-file=#{pkgetc}/cert.pem
      --with-guile-site-dir=#{share}/guile/site/3.0
      --with-guile-site-ccache-dir=#{lib}/guile/3.0/site-ccache
      --with-guile-extension-dir=#{lib}/guile/3.0/extensions
      --disable-heartbeat-support
      --with-p11-kit
    ]

    # Work around a gnulib issue with macOS Catalina
    args << "gl_cv_func_ftello_works=yes"

    system "./configure", *args
    # Adding LDFLAGS= to allow the build on Catalina 10.15.4
    # See https://gitlab.com/gnutls/gnutls/-/issues/966
    system "make", "LDFLAGS=", "install"

    # certtool shadows the macOS certtool utility
    mv bin/"certtool", bin/"gnutls-certtool"
    mv man1/"certtool.1", man1/"gnutls-certtool.1"
  end

  def post_install
    keychains = %w[
      /System/Library/Keychains/SystemRootCertificates.keychain
    ]

    certs_list = `security find-certificate -a -p #{keychains.join(" ")}`
    certs = certs_list.scan(/-----BEGIN CERTIFICATE-----.*?-----END CERTIFICATE-----/m)

    valid_certs = certs.select do |cert|
      IO.popen("openssl x509 -inform pem -checkend 0 -noout", "w") do |openssl_io|
        openssl_io.write(cert)
        openssl_io.close_write
      end

      $CHILD_STATUS.success?
    end

    pkgetc.mkpath
    (pkgetc/"cert.pem").atomic_write(valid_certs.join("\n"))
  end

  def caveats
    <<~EOS
      If you are going to use the Guile bindings you will need to add the following
      to your .bashrc or equivalent in order for Guile to find the TLS certificates
      database:
        export GUILE_TLS_CERTIFICATE_DIRECTORY=/usr/local/etc/gnutls/
    EOS
  end

  test do
    system bin/"gnutls-cli", "--version"

    gnutls = testpath/"gnutls.scm"
    gnutls.write <<~EOS
      (use-modules (gnutls))
      (gnutls-version)
    EOS

    ENV["GUILE_AUTO_COMPILE"] = "0"
    ENV["GUILE_LOAD_PATH"] = HOMEBREW_PREFIX/"share/guile/site/3.0"
    ENV["GUILE_LOAD_COMPILED_PATH"] = HOMEBREW_PREFIX/"lib/guile/3.0/site-ccache"
    ENV["GUILE_SYSTEM_EXTENSIONS_PATH"] = HOMEBREW_PREFIX/"lib/guile/3.0/extensions"

    system "guile", gnutls
  end
end
