_: {
  services.matrix-tuwunel = {
    enable = true;
    settings.global = {
      server_name = "mux.im";
      port = [ 6167 ];
    };
  };
}
