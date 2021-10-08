(self: super: {
  tlp = super.tlp.overrideAttrs (old: {
    version = "1.4.0";
  });
})
