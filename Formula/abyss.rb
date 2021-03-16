class Abyss < Formula
  desc "Genome sequence assembler for short reads"
  homepage "https://www.bcgsc.ca/resources/software/abyss"
  url "https://github.com/bcgsc/abyss/releases/download/2.2.5/abyss-2.2.5.tar.gz"
  sha256 "38e886f455074c76b32dd549e94cc345f46cb1d33ab11ad3e8e1f5214fc65521"
  license all_of: ["GPL-3.0-only", "LGPL-2.1-or-later", "MIT", "BSD-3-Clause"]

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any, arm64_big_sur: "4f653f5b026d1ed8c2b0ced4f47a13bf13cbef542ca1c14d9ef4a9ac2feca90b"
    sha256 cellar: :any, big_sur:       "9fe0e2f711647eda6cfc6f4dc8ff0259f6fa96534fa1bfa9f895cfc2b62830b6"
    sha256 cellar: :any, catalina:      "521a584ab5f11e69de3b4b2362bdcf89cf3b541b32694c30eec6e71d334c8232"
    sha256 cellar: :any, mojave:        "8c473ad4f6d9c3b786069c1d933d1ee8e72fb117f1ddbef65b0696163cf34292"
    sha256 cellar: :any, high_sierra:   "7fbea49ff3c1cdf2867ceac467be40d16a37cf104ef7fcd478faf0cfdd726eea"
  end

  head do
    url "https://github.com/bcgsc/abyss.git"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "multimarkdown" => :build
  end

  depends_on "boost" => :build
  depends_on "google-sparsehash" => :build
  depends_on "open-mpi"

  on_macos do
    depends_on "gcc"
  end

  fails_with :clang # no OpenMP support

  resource("testdata") do
    url "https://www.bcgsc.ca/sites/default/files/bioinformatics/software/abyss/releases/1.3.4/test-data.tar.gz"
    sha256 "28f8592203daf2d7c3b90887f9344ea54fda39451464a306ef0226224e5f4f0e"
  end

  def install
    ENV.delete("HOMEBREW_SDKROOT") if MacOS.version >= :mojave && MacOS::CLT.installed?
    system "./autogen.sh" if build.head?
    system "./configure", "--enable-maxk=128",
                          "--prefix=#{prefix}",
                          "--with-boost=#{Formula["boost"].include}",
                          "--with-mpi=#{Formula["open-mpi"].prefix}",
                          "--with-sparsehash=#{Formula["google-sparsehash"].prefix}",
                          "--disable-dependency-tracking",
                          "--disable-silent-rules"
    system "make", "install"
  end

  test do
    testpath.install resource("testdata")
    if which("column")
      system "#{bin}/abyss-pe", "k=25", "name=ts", "in=reads1.fastq reads2.fastq"
    else
      # Fix error: abyss-tabtomd: column: not found
      system "#{bin}/abyss-pe", "unitigs", "scaffolds", "k=25", "name=ts", "in=reads1.fastq reads2.fastq"
    end
    system "#{bin}/abyss-fac", "ts-unitigs.fa"
  end
end
