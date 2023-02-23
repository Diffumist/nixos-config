{ buildGo119Module, source, pkgs, lib, }:
buildGo119Module rec {
  inherit (source) pname version src;
  vendorSha256 = "sha256-3j+5fF57eu7JJd3rnrWYwuWDivycUkUTTzptYaK3G/Q=";
  # Do not build testing suit
  excludedPackages = [ "./test" ];
  CGO_ENABLED = 0;
  ldflags = [
    "-s"
    "-w"
    "-X github.com/Dreamacro/clash/constant.Version=dev-${version}"
    "-X github.com/Dreamacro/clash/constant.BuildTime=${version}"
  ];
  tags = [
    "with_gvisor"
  ];
  # Network required 
  doCheck = false;
}
