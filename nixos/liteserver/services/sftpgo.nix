{ pkgs, config, ... }:
{
  services.sftpgo = {
    enable = true;
    settings = {
      httpd.bindings = [
        {
          address = "127.0.0.1";
          port = 8080;
          enable_web_admin = true;
          enable_web_client = true;
        }
      ];

      webdavd.bindings = [
        {
          address = "127.0.0.1";
          port = 6065;
        }
      ];
    };
  };

  systemd.services.sftpgo.serviceConfig.EnvironmentFile = [
    config.sops.secrets.sftpgo_env.path
    config.sops.secrets.webdav_env.path
  ];
}
