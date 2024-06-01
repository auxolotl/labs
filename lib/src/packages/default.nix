lib: {
  packages = {
    # TODO: Document this.
    isDerivation = value: value.type or null == "derivation";

    # TODO: Document this.
    sanitizeDerivationName = let
      validate = builtins.match "[[:alnum:]+_?=-][[:alnum:]+._?=-]*";
    in
      value:
      # First detect the common case of already valid strings, to speed those up
        if builtins.stringLength value <= 207 && validate value != null
        then builtins.unsafeDiscardStringContext value
        else
          lib.fp.pipe value [
            # Get rid of string context. This is safe under the assumption that the
            # resulting string is only used as a derivation name
            builtins.unsafeDiscardStringContext

            # Strip all leading "."
            (x: builtins.elemAt (builtins.match "\\.*(.*)" x) 0)

            (lib.strings.split "[^[:alnum:]+._?=-]+")

            # Replace invalid character ranges with a "-"
            (lib.strings.concatMap (x:
              if builtins.isList x
              then "-"
              else x))

            # Limit to 211 characters (minus 4 chars for ".drv")
            (x: builtins.substring (lib.math.max (builtins.stringLength x - 207) 0) (-1) x)

            # If the result is empty, replace it with "unknown"
            (x:
              if builtins.stringLength x == 0
              then "unknown"
              else x)
          ];
  };
}
