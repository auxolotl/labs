lib: {
  generators = {
    ## Limit evaluation of a valud to a certain depth.
    ##
    ## @type { limit? :: Int | Null, throw? :: Bool } -> a -> a
    withRecursion = {
      limit ? null,
      throw ? true,
    }:
      assert builtins.isInt limit; let
        special = [
          "__functor"
          "__functionArgs"
          "__toString"
          "__pretty__"
        ];
        attr = next: name:
          if builtins.elem name special
          then lib.fp.id
          else next;
        transform = depth:
          if limit != null && depth > limit
          then
            if throw
            then builtins.throw "Exceeded maximum eval-depth limit of ${builtins.toString limit} while trying to evaluate with `lib.generators.withRecursion'!"
            else lib.fp.const "<unevaluated>"
          else lib.fp.id;
        process = depth: value: let
          next = x: process (depth + 1) (transform (depth + 1) x);
        in
          if builtins.isAttrs value
          then builtins.mapAttrs (attr next) value
          else if builtins.isList value
          then builtins.map next value
          else transform (depth + 1) value;
      in
        process 0;

    ## Create a pretty printer for Nix values.
    ##
    ## @type { indent? :: String, multiline? :: Bool, allowCustomPrettifiers? :: Bool } -> a -> string
    pretty = {
      indent ? "",
      multiline ? true,
      allowCustomPrettifiers ? false,
    }: let
      process = indent: value: let
        prefix =
          if multiline
          then "\n${indent}  "
          else " ";
        suffix =
          if multiline
          then "\n${indent}"
          else " ";

        prettyNull = "null";
        prettyNumber = lib.numbers.into.string value;
        prettyBool = lib.bools.into.string value;
        prettyPath = builtins.toString value;

        prettyString = let
          lines = builtins.filter (x: !builtins.isList x) (builtins.split "\n" value);
          escapeSingleline = lib.strings.escape.any ["\\" "\"" "\${"];
          escapeMultiline = builtins.replaceStrings ["\${" "''"] ["''\${" "'''"];
          singlelineResult = "\"" + lib.strings.concatMapSep "\\n" escapeSingleline lines + "\"";
          multilineResult = let
            escapedLines = builtins.map escapeMultiline lines;
            # The last line gets a special treatment: if it's empty, '' is on its own line at the "outer"
            # indentation level. Otherwise, '' is appended to the last line.
            lastLine = lib.last escapedLines;
            contents = builtins.concatStringsSep prefix (lib.lists.init escapedLines);
            contentsSuffix =
              if lastLine == ""
              then suffix
              else prefix + lastLine;
          in
            "''"
            + prefix
            + contents
            + contentsSuffix
            + "''";
        in
          if multiline && builtins.length lines > 1
          then multilineResult
          else singlelineResult;

        prettyList = let
          contents = lib.strings.concatMapSep prefix (process (indent + "  ")) value;
        in
          if builtins.length value == 0
          then "[ ]"
          else "[${prefix}${contents}${suffix}]";

        prettyFunction = let
          args = lib.fp.args value;
          markArgOptional = name: default:
            if default
            then name + "?"
            else name;
          argsWithDefaults = lib.attrs.mapToList markArgOptional args;
          serializedArgs = builtins.concatStringsSep ", " argsWithDefaults;
        in
          if args == {}
          then "<function>"
          else "<function, args: {${serializedArgs}}>";

        prettyAttrs = let
          contents = builtins.concatStringsSep prefix (lib.attrs.mapToList
            (name: value: "${lib.strings.escape.nix.identifier name} = ${
              builtins.addErrorContext "while evaluating an attribute `${name}`"
              (process (indent + "  ") value)
            };")
            value);
        in
          if allowCustomPrettifiers && value ? __pretty__ && value ? value
          then value.__pretty__ value.value
          else if value == {}
          then "{ }"
          else if lib.packages.isDerivation value
          then "<derivation ${value.name or "???"}>"
          else "{${prefix}${contents}${suffix}}";
      in
        if null == value
        then prettyNull
        else if builtins.isInt value || builtins.isFloat value
        then prettyNumber
        else if builtins.isBool value
        then prettyBool
        else if builtins.isString value
        then prettyString
        else if builtins.isPath value
        then prettyPath
        else if builtins.isList value
        then prettyList
        else if builtins.isFunction value
        then prettyFunction
        else if builtins.isAttrs value
        then prettyAttrs
        else builtins.abort "lib.generators.pretty: should never happen (value = ${value})";
    in
      process indent;
  };
}
