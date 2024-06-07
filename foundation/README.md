# Aux Foundation

Aux Foundation provides a set of foundational packages which are required for bootstrapping
a larger package set.

## Usage

Packages can be imported both with and without Nix Flakes. To import them using Nix Flakes,
add this repository as an input.

```nix
inputs.foundation.url = "github:auxolotl/labs?dir=foundation";
```

To import this library without using Nix Flakes, you will need to use `fetchTarball` and
import the library entrypoint.

```nix
let
    labs = builtins.fetchTarball {
        url = "https://github.com/auxolotl/labs/archive/main.tar.gz";
        sha256 = "<sha256>";
    };
    foundation = import "${labs}/foundation";
in
    # ...
```

## Development

This foundational package set is created using modules. Each builder and package is separated
accordingly and can be found in their respective directories. In addition, packages are grouped
into the different stages of the bootstrapping process.

### Inputs

Due to the fundamental nature of this project, the only accepted input is `lib` which itself
has no dependencies. _Everything_ else must be built from scratch in the package set.

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

### Builders

Builders are wrappers around `builtins.derivation` and provide additional functionality via
abstraction. They can be found in [`./src/builders`](./src/builders). Each builder specifies
its own `build` function which can be called elsewhere in the package set to construct packages.

For example, here is a module that makes use of the `kaem` builder:

```nix
{config}: let
    builders = config.aux.foundation.builders;
    stage0 = config.aux.foundation.stages.stage0;

    package = builders.kaem.build {
        name = "my-package";

        deps.build.host = [
            stage0.mescc-tools.package
            stage0.mescc-tools-extra.package
        ];

        script = ''
            mkdir ''${out}/bin
            cp ${./my-binary} ''${out}/bin/my-package
            chmod 555 ''${out}/bin/my-package
        '';
    };
in
    # ...
```

### Stages

The bootstrapping process is broken up into different stages which focus on different goals.
Each stage can be found in [`./src/stages`](./src/stages).

#### Stage 0

This stage is responsible for starting with a single binary seed and producing the tools
necessary to compile (simple) C code. This stage will then compile the original tools it
used from C sources.

#### Stage 1

This stage is responsible for building up to a recent version of `gcc`. Along with the
compiler, this stage provides things like `coreutils`, `binutils`, `gnumake`, and several
other important tools.
