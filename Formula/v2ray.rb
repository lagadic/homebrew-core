class V2ray < Formula
  desc "Platform for building proxies to bypass network restrictions"
  homepage "https://v2fly.org/"
  url "https://github.com/v2fly/v2ray-core/archive/v4.34.0.tar.gz"
  sha256 "b250f569cb0369f394f63184e748f1df0c90500feb8a1bf2276257c4c8b81bee"
  license all_of: ["MIT", "CC-BY-SA-4.0"]
  revision 1
  head "https://github.com/v2fly/v2ray-core.git"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_big_sur: "39e0fecf6a2dbc8aca5f2facc432798536a8e35ebeef377cda4ab02bfb1e8cdc"
    sha256 cellar: :any_skip_relocation, big_sur:       "e541ae09483383c6cdfd87eb1dd4a84c1f17bceadc6b48f3ed7ee87eaa17d6ad"
    sha256 cellar: :any_skip_relocation, catalina:      "ec07583f0a3a3f02fb038e9cffc76300b1389f5bd0dc46e48d8af7981a024c75"
    sha256 cellar: :any_skip_relocation, mojave:        "5d39350cde27080202514c4ba5fbe18197b77c4ae7ccd3d4c4677642e922c8b5"
  end

  depends_on "go" => :build

  resource "geoip" do
    url "https://github.com/v2fly/geoip/releases/download/202011190012/geoip.dat"
    sha256 "022e6426f66cd7093fc2454c28537d2345b4fce49dc97b81ddfec07ce54e7081"
  end

  resource "geosite" do
    url "https://github.com/v2fly/domain-list-community/releases/download/20201122065644/dlc.dat"
    sha256 "574af5247bb83db844be03038c8fed1e488bf4bd4ce5de2843847cf40be923c1"
  end

  def install
    ldflags = "-s -w -buildid="
    execpath = libexec/name
    system "go", "build", *std_go_args, "-o", execpath,
                 "-ldflags", ldflags,
                 "./main"
    system "go", "build", *std_go_args,
                 "-ldflags", ldflags,
                 "-tags", "confonly",
                 "-o", bin/"v2ctl",
                 "./infra/control/main"
    (bin/"v2ray").write_env_script execpath,
      V2RAY_LOCATION_ASSET: pkgshare

    pkgetc.install "release/config/config.json" => "config.json"

    resource("geoip").stage do
      pkgshare.install "geoip.dat"
    end

    resource("geosite").stage do
      pkgshare.install "dlc.dat" => "geosite.dat"
    end
  end

  plist_options manual: "v2ray -config=#{HOMEBREW_PREFIX}/etc/v2ray/config.json"

  def plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>#{plist_name}</string>
          <key>ProgramArguments</key>
          <array>
            <string>#{bin}/v2ray</string>
            <string>-config</string>
            <string>#{etc}/v2ray/config.json</string>
          </array>
          <key>KeepAlive</key>
          <true/>
          <key>RunAtLoad</key>
          <true/>
        </dict>
      </plist>
    EOS
  end

  test do
    (testpath/"config.json").write <<~EOS
      {
        "log": {
          "access": "#{testpath}/log"
        },
        "outbounds": [
          {
            "protocol": "freedom",
            "tag": "direct"
          }
        ],
        "routing": {
          "rules": [
            {
              "ip": [
                "geoip:private"
              ],
              "outboundTag": "direct",
              "type": "field"
            }
          ]
        }
      }
    EOS
    output = shell_output "#{bin}/v2ray -c #{testpath}/config.json -test"

    assert_match "Configuration OK", output
    assert_predicate testpath/"log", :exist?
  end
end
