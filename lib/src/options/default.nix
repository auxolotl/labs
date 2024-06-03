lib: {
  options = {
    merge = {
      ## Merge a list of option definitions into a single value.
      ##
      ## @type Location -> List Definition -> Any
      default = location: definitions: let
        values = lib.options.getDefinitionValues definitions;
        first = builtins.elemAt values 0;
        mergedFunctions = x:
          lib.options.mergeDefault
          location
          (builtins.map (f: f x) values);
        mergedLists = builtins.concatLists values;
        mergedAttrs = builtins.foldl' lib.attrs.merge {} values;
        mergedBools = builtins.any lib.bools.or false values;
        mergedStrings = lib.strings.concat values;
      in
        if builtins.length values == 1
        then builtins.elemAt values 0
        else if builtins.all builtins.isFunction values
        then mergedFunctions
        else if builtins.all builtins.isList values
        then mergedLists
        else if builtins.all builtins.isAttrs values
        then mergedAttrs
        else if builtins.all builtins.isBool values
        then mergedBools
        else if builtins.all lib.strings.isString values
        then mergedStrings
        else if builtins.all builtins.isInt values && builtins.all (x: x == first) values
        then first
        # TODO: Improve this error message to show the location and definitions for the option.
        else builtins.throw "Cannot merge definitions.";

      ## Merge multiple option definitions together.
      ##
      ## @type Location -> Type -> List Definition
      definitions = location: type: definitions: let
        identifier = lib.options.getIdentifier location;
        resolve = definition: let
          properties =
            builtins.addErrorContext
            "while evaluating definitions from `${definition.__file__}`:"
            (lib.modules.apply.properties definition.value);
          normalize = value: {
            __file__ = definition.__file__;
            inherit value;
          };
        in
          builtins.map normalize properties;

        resolved = builtins.concatMap resolve definitions;
        overridden = lib.modules.apply.overrides resolved;

        values =
          if builtins.any (definition: lib.types.is "order" definition.value) overridden.values
          then lib.modules.apply.order overridden.values
          else overridden.values;

        isDefined = values != [];

        invalid = builtins.filter (definition: !(type.check definition.value)) values;

        merged =
          if isDefined
          then
            if builtins.all (definition: type.check definition.value) values
            then type.merge location values
            else builtins.throw "A definition for `${identifier}` is not of type `${type.description}`. Definition values:${lib.options.getDefinitions invalid}"
          else builtins.throw "The option `${identifier}` is used but not defined.";

        optional =
          if isDefined
          then {value = merged;}
          else {};
      in {
        inherit isDefined values merged optional;

        raw = {
          inherit values;
          inherit (overridden) highestPriority;
        };
      };

      ## Merge multiple option declarations together.
      ##
      ## @type Location -> List Option
      declarations = location: options: let
        merge = result: option: let
          mergedType = result.type.mergeType option.options.type.functor;
          isTypeMergeable = mergedType != null;
          shared = name: option.options ? ${name} && result ? ${name};
          typeSet = lib.attrs.when ((shared "type") && isTypeMergeable) {
            type = mergedType;
          };
          files = builtins.map lib.modules.getFiles result.declarations;
          serializedFiles = builtins.concatStringsSep " and " files;
          getSubModules = option.options.type.getSubModules or null;
          submodules =
            if getSubModules != null
            then
              builtins.map
              (module: {
                __file__ = option.__file__;
                includes = [module];
              })
              getSubModules
              ++ result.options
            else result.options;
        in
          if shared "default" || shared "example" || shared "description" || shared "apply" || (shared "type" && !isTypeMergeable)
          then builtins.throw "The option `${lib.options.getIdentifier location}` in `${option.__file__}` is already declared in ${serializedFiles}"
          else
            option.options
            // result
            // {
              declarations = result.declarations ++ [option.__file__];
              options = submodules;
            }
            // typeSet;
      in
        builtins.foldl'
        merge
        {
          inherit location;
          declarations = [];
          options = [];
        }
        options;

      ## Merge an option, only supporting a single unique definition.
      ##
      ## @type String -> Location -> List Definition -> Any
      unique = message: location: definitions: let
        identifier = lib.options.getIdentifier location;
        total = builtins.length definitions;
        first = builtins.elemAt definitions 0;
      in
        if total == 1
        then first.value
        else if total == 0
        then builtins.throw "Cannot merge unused option `${identifier}`.\n${message}"
        else builtins.throw "The option `${identifier}` is defined multiple times, but must be unique.\n${message}\nDefinitions:${lib.options.getDefinitions definitions}";

      ## Merge a single instance of an option.
      ##
      ## @type Location -> List Definition -> Any
      one = lib.options.merge.unique "";

      equal = location: definitions: let
        identifier = lib.options.getIdentifier location;
        first = builtins.elemAt definitions 0;
        rest = builtins.tail definitions;
        merge = x: y:
          if x != y
          then builtins.throw "The option `${identifier}` has conflicting definitions:${lib.options.getDefinitions definitions}"
          else x;
        merged = builtins.foldl' merge first rest;
      in
        if builtins.length definitions == 0
        then builtins.throw "Cannot merge unused option `${identifier}`."
        else if builtins.length definitions == 1
        then first.value
        else merged.value;
    };

    ## Check whether a value is an option.
    ##
    ## @type Attrs -> Bool
    is = lib.types.is "option";

    ## Create an option.
    ##
    ## @type { type? :: String | Null, apply? :: (a -> b) | Null, default? :: { value :: a, text :: String }, example? :: String | Null, visible? :: Bool | Null, internal? :: Bool | Null, writable? :: Bool | Null, description? :: String | Null } -> Option a
    create = settings @ {
      type ? lib.types.unspecified,
      apply ? null,
      default ? {},
      example ? null,
      visible ? null,
      internal ? null,
      writable ? null,
      description ? null,
    }: {
      __type__ = "option";
      inherit type apply default example visible internal writable description;
    };

    ## Create a sink option.
    ##
    ## @type @alias lib.options.create
    sink = settings: let
      defaults = {
        internal = true;
        visible = false;
        default = false;
        description = "A sink option for unused definitions";
        type = lib.types.create {
          name = "sink";
          check = lib.fp.const true;
          merge = lib.fp.const (lib.fp.const false);
        };
        apply = value: builtins.throw "Cannot read the value of a Sink option.";
      };
    in
      lib.options.create (defaults // settings);

    ## Get the definition values from a list of options definitions.
    ##
    ## @type List Definition -> Any
    getDefinitionValues = definitions:
      builtins.map (definition: definition.value) definitions;

    ## Convert a list of option identifiers into a single identifier.
    ##
    ## @type List String -> String
    getIdentifier = location: let
      special = [
        # lib.types.attrs.of (lib.types.submodule {})
        "<name>"
        # lib.types.list.of (submodule {})
        "*"
        # lib.types.function
        "<function body>"
      ];
      escape = part:
        if builtins.elem part special
        then part
        else lib.strings.escape.nix.identifier part;
    in
      lib.strings.concatMapSep "." escape location;

    ## Get a string message of the definitions for an option.
    ##
    ## @type List Definition -> String
    getDefinitions = definitions: let
      serialize = definition: let
        valueWithRecursionLimit =
          lib.generators.withRecursion {
            limit = 10;
            throw = false;
          }
          definition.value;

        eval = builtins.tryEval (
          lib.generators.pretty {}
          valueWithRecursionLimit
        );

        lines = lib.strings.split "\n" eval.value;
        linesLength = builtins.length lines;
        firstFiveLines = lib.lists.take 5 lines;

        ellipsis = lib.lists.when (linesLength > 5) "...";

        value = builtins.concatStringsSep "\n    " (firstFiveLines ++ ellipsis);

        result =
          if ! eval.success
          then ""
          else if linesLength > 1
          then ":\n    " + value
          else ": " + value;
      in "\n- In `${definition.__file__}`${result}";
    in
      lib.strings.concatMap serialize definitions;

    ## Run a set of definitions, calculating the resolved value and associated information.
    ##
    ## @type Location -> Option -> List Definition -> String & { value :: Any, highestPriority :: Int, isDefined :: Bool, files :: List String, definitions :: List Any, definitionsWithLocations :: List Definition }
    run = location: option: definitions: let
      identifier = lib.options.getIdentifier location;

      definitionsWithDefault =
        if option ? default && option.default ? value
        then
          [
            {
              __file__ = builtins.head option.declarations;
              value = lib.modules.overrides.option option.default.value;
            }
          ]
          ++ definitions
        else definitions;

      merged =
        if option.writable or null == false && builtins.length definitionsWithDefault > 1
        then let
          separatedDefinitions = builtins.map (definition:
            definition
            // {
              value = (lib.options.merge.definitions location option.type [definition]).merged;
            })
          definitionsWithDefault;
        in
          builtins.throw "The option `${identifier}` is not writable, but is set more than once:${lib.options.getDefinitions separatedDefinitions}"
        else lib.options.merge.definitions location option.type definitionsWithDefault;

      value =
        if option.apply or null != null
        then option.apply merged.merged
        else merged.merged;
    in
      option
      // {
        value = builtins.addErrorContext "while evaluating the option `${identifier}`:" value;
        highestPriority = merged.raw.highestPriority;
        isDefined = merged.isDefined;
        files = builtins.map (definition: definition.__file__) merged.values;
        definitions = lib.options.getDefinitionValues merged.values;
        definitionsWithLocations = merged.values;
        __toString = identifier;
      };
  };
}
