lib: {
  packages = {
    ## Check whether a value is a derivation. Note that this will also return true
    ## for "fake" derivations which are constructed by helpers such as
    ## `lib.paths.into.drv` for convenience.
    ##
    ## @type a -> Bool
    isDerivation = value:
      value.type or null == "derivation";

    ## Sanitize a string to produce a valid name for a derivation.
    ##
    ## @type String -> String
    sanitizeDerivationName = let
      validate = builtins.match "[[:alnum:]+_?=-][[:alnum:]+._?=-]*";
    in
      value:
      # First detect the common case of already valid strings, to speed those up
        if builtins.stringLength value <= 207 && validate value != null
        then builtins.unsafeDiscardStringContext value
        else
          lib.fp.pipe [
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
          ]
          value;

    ## Get an output of a derivation.
    ##
    ## @type String -> Derivation -> String
    getOutput = output: package:
      if ! package ? outputSpecified || !package.outputSpecified
      then package.${output} or package.out or package
      else package;
  };
}
