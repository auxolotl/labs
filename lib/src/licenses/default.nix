lib: {
  licenses = let
    raw = import ./all.nix;

    defaults = name: {
      inherit name;
      free = true;
    };

    withDefaults = name: license: (defaults name) // license;
    withSpdx = license:
      if license ? spdx
      then
        license
        // {
          url = "https://spdx.org/licenses/${license.spdx}.html";
        }
      else license;
    withRedistributable = license:
      {
        redistributable = license.free;
      }
      // license;

    normalize = name:
      lib.fp.pipe [
        (withDefaults name)
        withSpdx
        withRedistributable
      ];
  in
    builtins.mapAttrs normalize raw;
}
