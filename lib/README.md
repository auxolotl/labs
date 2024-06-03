# Aux Lib

Aux Lib is intended to be a replacement for NixPkg's `lib` with stronger constraints around naming,
organization, and inclusion of functions. In addition to replacing library functions, Aux Lib also
defines a revamped version of the NixOS Module system intended to make it easier, more approachable,
and intuitive.

## Usage

The library can be imported both with and without Nix Flakes. To import the library using Nix Flakes,
add this repository as an input.

```nix
inputs.lib.url = "github:auxolotl/labs?dir=lib";
```

To import the library without using Nix Flakes, you will need to use `fetchTarball` and import the
library entrypoint.

```nix
let
    labs = builtins.fetchTarball {
        url = "https://github.com/auxolotl/labs/archive/main.tar.gz";
        sha256 = "<sha256>";
    };
    lib = import "${labs}/lib";
in
    # ...
```

## Development

To contribute to the project, we accept pull requests to this repository. Please see the following
sections for information on the appropriate practices and required steps for working on Aux Lib.

### Documentation

We want our code to survive in the world, but without proper documentation that won't happen. In
order to not lose knowledge and also make it easier for others to begin participating in the
project we require that every function have an appropriate documentation comment. The format for
these comments is as follows:

```nix
let
    ## This is a description of what the function does. Any necessary information can be added
    ## here. After this point comes a gap before a Hindley-Milner style type signature. Note
    ## that these types are not actually checked, but serve as a helpful addition for the user
    ## in addition to being provided in generated documentation.
    ##
    ## @type Int -> String
    func = x: builtins.toString x;
in
    # ...
```

### Testing

All functions that are added to the project should include tests. The test suites are located
next to their implementation in files ending in `.test.nix`. These tests should ensure that
the library behaves as expected. The typical structure of these test suites is:

```nix
let
    lib = import ./../default.nix;
in
{
    "my function" = {
        "test 1" = let
            expected = 1;
            input = {};
            actual = lib.myFunction input;
        in
            actual == expected;
    };
}
```

Successful tests will return `true` while failing test will resolve with `false`. You can run
all tests with the following command:

```shell
./test.sh
```

If you want to run a specific test suite, you can run the command, specifying the directory
to the tests file:

```shell
./test.sh $namespace
```

For example, to run the tests for only `attrs`, use the following command:

```shell
./test.sh attrs
```

### Formatting

> **Note:** To keep this flake light and keep its inputs empty we do not include a package
> set which would provide a formatter. Instead please run `nix run nixpkgs#nixfmt-rfc-style`
> until an improved solution is available.

All code in this project must be formatted using the provided formatter in the `flake.nix`
file. You can run this formatter using the command `nix fmt` (not currently available).

### Code Quality

In order to keep the project approachable and easy to maintain, certain patterns are not allowed.
In particular, the use of `with` and `rec` are not allowed. Additionally, you should prefer the
fully qualified name of a variable rather than creating intermediate ones using `inherit`.

### Adding Functionality

Before adding new features to the library, submit an issue or talk the idea over with one or
more of the project maintainers. We want to make sure that the library does not become bloated
with tools that aren't used. Some features may be better handled in a separate project. If you
do get the go-ahead to begin working on your feature, please place it in the library structure
similarly to how existing features are. For example, things dealing with strings should go in
`src/strings/default.nix`.

Additionally, you should prefer to group things in attribute sets for like-functionality. More
broad categories such as `strings` and `lists` are helpful, but scoped groups for things like
`into`, `from`, and `validate` also make the library more discoverable. Having all of the
different parts of the library mirroring this organizational structure makes building intuition
for working with the library much easier. To know when to group new things, consider the
following:

- Would your function name be multiple words like `fromString`?
- Are there multiple variants of this function?
- Would it be easier to find in a group?
- Would grouping help avoid name collisions or confusion?
