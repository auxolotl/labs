let
  lib = import ./../default.nix;
in {
  "extend" = {
    "lib is extensible" = let
      result = lib.extend (final: prev: prev // {
        __injected__ = true;

        fp = prev.fp // {
          __injected__ = true;
        };
      });
    in
      result ? __injected__
        && result.fp ? __injected__
        && result.fp ? const;
  };
}
