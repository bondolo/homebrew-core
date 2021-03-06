class Bcrypt < Formula
  desc "Cross platform file encryption utility using blowfish"
  homepage "https://bcrypt.sourceforge.io/"
  url "https://bcrypt.sourceforge.io/bcrypt-1.1.tar.gz"
  sha256 "b9c1a7c0996a305465135b90123b0c63adbb5fa7c47a24b3f347deb2696d417d"

  livecheck do
    url "http://bcrypt.sourceforge.net"
    strategy :page_match
    regex(/href=.*?bcrypt[._-]v?(\d+(?:\.\d+)+)\.t/i)
  end

  bottle do
    cellar :any_skip_relocation
    sha256 "1e9d946fdf6761cf3ef623ac4646f5d77107aca427ae5d986a25f5ef7de6ceea" => :catalina
    sha256 "ef0fbaf77cad63f0450bde11bd6ba89fe2217ecb0f95b1952dd93c56730f615e" => :mojave
    sha256 "70235a007382bbbaeddbfc52b503e86b6cadcb7d07b752d97c8ce0861bccd3a8" => :high_sierra
    sha256 "913cfce96b6de1fce20ee1ff771ef22e3663f3da6c7529d7efc3a43b0e1d92b8" => :sierra
    sha256 "d674203ce681f17519eee1ce7a3258615b2de5a8a12460d7de284af09028d7da" => :el_capitan
    sha256 "dbd530bd84a1e92120aacf07f60e3b6131c92421702ab8b9f9e02d3b72a00ad6" => :yosemite
    sha256 "2a0a662d778677d75222745b30e6c5e825078855d303cf853609f50b1ceca4a6" => :mavericks
  end

  def install
    system "make", "CC=#{ENV.cc}",
                   "CFLAGS=#{ENV.cflags}",
                   "LDFLAGS=-lz"
    bin.install "bcrypt"
    man1.install gzip("bcrypt.1")
  end

  test do
    (testpath/"test.txt").write("Hello World!")
    pipe_output("#{bin}/bcrypt -r test.txt", "12345678\n12345678\n")
    mv "test.txt.bfe", "test.out.txt.bfe"
    pipe_output("#{bin}/bcrypt -r test.out.txt.bfe", "12345678\n")
    assert_equal File.read("test.txt"), File.read("test.out.txt")
  end
end
