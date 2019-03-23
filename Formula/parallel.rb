class Parallel < Formula
  desc "Shell command parallelization utility"
  homepage "https://savannah.gnu.org/projects/parallel/"
  url "https://ftp.gnu.org/gnu/parallel/parallel-20190322.tar.bz2"
  mirror "https://ftpmirror.gnu.org/parallel/parallel-20190322.tar.bz2"
  sha256 "d507c26feba70a2da43a691ab31e44e9a04f635e98c9d3a7e72980db80f6008b"
  head "https://git.savannah.gnu.org/git/parallel.git"

  bottle do
    cellar :any_skip_relocation
    sha256 "98ccb32d55b0b0d21746b8d2b038d6c65afaedbe66e61ec5eeace11280721c25" => :mojave
    sha256 "98ccb32d55b0b0d21746b8d2b038d6c65afaedbe66e61ec5eeace11280721c25" => :high_sierra
    sha256 "9b1adf1e0e49e8cf1a297ce247d1a3cd0709751e00787085c1e2855caf64df9a" => :sierra
  end

  if Tab.for_name("moreutils").with?("parallel")
    conflicts_with "moreutils",
      :because => "both install a `parallel` executable."
  end

  def install
    system "./configure", "--prefix=#{prefix}"
    system "make", "install"
  end

  test do
    assert_equal "test\ntest\n",
                 shell_output("#{bin}/parallel --will-cite echo ::: test test")
  end
end
