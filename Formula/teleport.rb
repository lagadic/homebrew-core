class Teleport < Formula
  desc "Modern SSH server for teams managing distributed infrastructure"
  homepage "https://gravitational.com/teleport"
  url "https://github.com/gravitational/teleport/archive/v6.0.0.tar.gz"
  sha256 "65452e2e116ad9ef7eca70081f7b24f7150dd328d1d556583d2fb7da4d0473a1"
  license "Apache-2.0"
  head "https://github.com/gravitational/teleport.git"

  # We check the Git tags instead of using the `GithubLatest` strategy, as the
  # "latest" version can be incorrect. As of writing, two major versions of
  # `teleport` are being maintained side by side and the "latest" tag can point
  # to a release from the older major version.
  livecheck do
    url :stable
    strategy :git
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_big_sur: "88d22a08f1af717e7d13ffcaf3a884edb59a689c59016de6fe20c69d3153347b"
    sha256 cellar: :any_skip_relocation, big_sur:       "91642057a55449bdd4ebe14455aaeac3844c9d3200a56417572dd87f8ebfc94e"
    sha256 cellar: :any_skip_relocation, catalina:      "f6abd2cec2fe0965bf899b98ce06a9fe3f82618d4d540a009c059fa9eb959b4b"
    sha256 cellar: :any_skip_relocation, mojave:        "d6db0fa21ab1da99f66e2009fc3905c7da70220bc3d305c8d3356fd3fe520148"
  end

  depends_on "go" => :build

  uses_from_macos "curl" => :test
  uses_from_macos "netcat" => :test
  uses_from_macos "zip"

  conflicts_with "etsh", because: "both install `tsh` binaries"

  # Keep this in sync with https://github.com/gravitational/teleport/tree/v#{version}
  resource "webassets" do
    url "https://github.com/gravitational/webassets/archive/228008d85ec49ed98385324bb4b5eb98bcad8bd7.tar.gz"
    sha256 "3269e7519c617dea2ca7b776cb74ee16344e4b80671e4baf4c8213691d914f99"
  end

  def install
    (buildpath/"webassets").install resource("webassets")
    ENV.deparallelize { system "make", "full" }
    bin.install Dir["build/*"]
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/teleport version")
    (testpath/"config.yml").write shell_output("#{bin}/teleport configure")
      .gsub("0.0.0.0", "127.0.0.1")
      .gsub("/var/lib/teleport", testpath)
      .gsub("/var/run", testpath)
      .gsub(/https_(.*)/, "")
    begin
      pid = spawn("#{bin}/teleport start -c #{testpath}/config.yml")
      sleep 5
      system "/usr/bin/curl", "--insecure", "https://localhost:3080"
      system "/usr/bin/nc", "-z", "localhost", "3022"
      system "/usr/bin/nc", "-z", "localhost", "3023"
      system "/usr/bin/nc", "-z", "localhost", "3025"
    ensure
      Process.kill(9, pid)
    end
  end
end
