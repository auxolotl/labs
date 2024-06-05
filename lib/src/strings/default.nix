lib: {
  strings = {
    into = {
      ## Convert a character to an integer.
      ##
      ## @type String -> Integer
      int = char: builtins.getAttr char lib.strings.ascii;

      ## Convert a string into a list of characters.
      ##
      ## @type String -> List String
      chars = value: let
        range = lib.lists.range 0 (builtins.stringLength value - 1);
        pick = index: builtins.substring index 1 value;
      in
        builtins.map pick range;

      shell = {
        ## Convert a value into a shell variable.
        ##
        ## @type String -> Any -> String
        var = name: target: let
          baseVar = "${name}=${lib.strings.escape.shell.arg target}";
          listVar = "declare -a ${name}=(${lib.strings.escape.shell.args target})";
          attrsVar = "declare -A ${name}=(${
            builtins.concatStringsSep " " (lib.attrs.mapToList
              (k: v: "[${lib.strings.escape.shell.arg k}]=${lib.strings.escape.shell.arg v}")
              target)
          })";
        in
          assert lib.errors.trace (lib.strings.validate.posix name) "Invalid shell variable name: ${name}";
            if builtins.isAttrs target && !lib.strings.validate.stringifiable target
            then attrsVar
            else if builtins.isList target
            then listVar
            else baseVar;

        ## Create shell variables for a map of values.
        ##
        ## @type Attrs -> String
        vars = target:
          builtins.concatStringsSep
          "\n"
          (lib.attrs.mapToList lib.strings.into.shell.var target);
      };
    };

    escape = {
      ## Escape parts of a string.
      ##
      ## @type List String -> String -> String
      any = patterns: source: let
        escaped = builtins.map (x: "\\${x}") patterns;
        replacer = builtins.replaceStrings patterns escaped;
      in
        replacer source;

      ## Escape a given set of characters in a string using their
      ## ASCII code prefixed with "\x".
      ##
      ## @type List String -> String
      c = list: let
        serialize = char: let
          hex = lib.numbers.into.hex (lib.strings.into.int char);
        in "\\x${lib.strings.lower hex}";
      in
        builtins.replaceStrings list (builtins.map serialize list);

      nix = {
        ## Escape a string of Nix code.
        ##
        ## @type String -> String
        value = value: lib.strings.escape.any ["$"] (builtins.toJSON value);

        ## Escape a string for use as a Nix identifier.
        ##
        ## @type String -> String
        identifier = value:
          if builtins.match "[a-zA-Z_][a-zA-Z0-9_'-]*" value != null
          then value
          else lib.strings.escape.nix.value value;
      };

      ## Escape a string for use in a regular expression.
      ##
      ## @type String -> String
      regex = lib.strings.escape.any (lib.strings.into.chars "\\[{()^$?*+|.");

      ## Escape a string for use in XML.
      ##
      ## @type String -> String
      xml =
        builtins.replaceStrings
        ["\"" "'" "<" ">" "&"]
        ["&quot;" "&apos;" "&lt;" "&gt;" "&amp;"];

      shell = {
        ## Escape a string for use as a shell argument.
        ##
        ## @type String -> String
        arg = value: "'${builtins.replaceStrings ["'"] ["'\\''"] (builtins.toString value)}'";

        ## Escape multiple strings for use as shell arguments.
        ##
        ## @type List String -> String
        args = lib.strings.concatMapSep " " lib.strings.escape.shell.arg;
      };
    };

    validate = {
      ## Check if a string is a valid POSIX identifier.
      ##
      ## @type String -> Bool
      posix = name: builtins.match "[a-zA-Z_][a-zA-Z0-9_]*" name != null;

      ## Check if a value can be used as a string.
      ##
      ## @type Any -> Bool
      stringifiable = value:
        builtins.isString value
        || builtins.isPath value
        || value ? outPath
        || value ? __toString;

      ## Check whether a string is empty. This includes strings that
      ## only contain whitespace.
      ##
      ## @type String -> Bool
      empty = value:
        builtins.match "[ \t\n]*" value != null;
    };

    ## Return a given string if a condition is true, otherwise return
    ## an empty string.
    ##
    ## @type Bool -> String -> String
    when = condition: value:
      if condition
      then value
      else "";

    ## A table of ASCII characters mapped to their integer character code.
    ##
    ## @type Attrs
    ascii = import ./ascii.nix;

    ## Lists of both upper and lower case ASCII characters.
    ##
    ## @type { upper :: List String, lower :: List String }
    alphabet = import ./alphabet.nix;

    ## Concatenate a list of strings together.
    ##
    ## @type List String -> String
    concat = builtins.concatStringsSep "";

    ## Concatenate and map a list of strings together.
    ##
    ## @type List String -> String
    concatMap = lib.strings.concatMapSep "";

    ## Concatenate and map a list of strings together with a separator.
    ##
    ## @type String -> (a -> String) -> List a -> String
    concatMapSep = separator: f: list:
      builtins.concatStringsSep separator (builtins.map f list);

    ## Change a string to uppercase.
    ##
    ## @type String -> String
    upper = builtins.replaceStrings lib.strings.alphabet.lower lib.strings.alphabet.upper;

    ## Change a string to lowercase.
    ##
    ## @type String -> String
    lower = builtins.replaceStrings lib.strings.alphabet.upper lib.strings.alphabet.lower;

    ## Add the context of one string to another.
    ##
    ## @type String -> String -> String
    withContext = context: value: builtins.substring 0 0 context + value;

    ## Split a string by a separator.
    ##
    ## @type String -> String -> List String
    split = separator: value: let
      escaped = lib.strings.escape.regex (builtins.toString separator);
      raw = builtins.split escaped (builtins.toString value);
      parts = builtins.filter builtins.isString raw;
    in
      builtins.map (lib.strings.withContext value) parts;

    ## Check if a string starts with a given prefix.
    ##
    ## @type String -> String -> Bool
    hasPrefix = prefix: value: let
      text = builtins.substring 0 (builtins.stringLength prefix) value;
    in
      text == prefix;

    ## Check if a string ends with a given suffix.
    ##
    ## @type String -> String -> Bool
    hasSuffix = suffix: value: let
      valueLength = builtins.stringLength value;
      suffixLength = builtins.stringLength suffix;
      text = builtins.substring (valueLength - suffixLength) valueLength value;
    in
      (valueLength >= suffixLength)
      && text == suffix;

    ## Check if a string contains a given infix.
    ##
    ## @type String -> String -> Bool
    hasInfix = infix: value:
      builtins.match ".*${lib.strings.escape.regex infix}.*" "${value}" != null;

    ## Remove a prefix from a string if it exists.
    ##
    ## @type String -> String -> String
    removePrefix = prefix: value: let
      prefixLength = builtins.stringLength prefix;
      valueLength = builtins.stringLength value;
    in
      if lib.strings.hasPrefix prefix value
      then builtins.substring prefixLength (valueLength - prefixLength) value
      else value;

    ## Remove a suffix from a string if it exists.
    ##
    ## @type String -> String -> String
    removeSuffix = suffix: value: let
      suffixLength = builtins.stringLength suffix;
      valueLength = builtins.stringLength value;
    in
      if lib.strings.hasSuffix suffix value
      then builtins.substring 0 (valueLength - suffixLength) value
      else value;

    ## Pad the start of a string with a character until it reaches
    ## a given length.
    ##
    ## @type Integer -> String -> String
    padStart = length: char: value: let
      valueLength = builtins.stringLength value;
      padding = builtins.genList (_: char) (length - valueLength);
    in
      if valueLength < length
      then (builtins.concatStringsSep "" padding) + value
      else value;

    ## Pad the end of a string with a character until it reaches
    ## a given length.
    ##
    ## @type Integer -> String -> String
    padEnd = length: char: value: let
      valueLength = builtins.stringLength value;
      padding = builtins.genList (_: char) (length - valueLength);
    in
      if valueLength < length
      then value + (builtins.concatStringsSep "" padding)
      else value;
  };
}
