{
  lib,
  config,
}: let
  system = config.aux.system;

  parts = lib.strings.split "-" system;

  platform = builtins.elemAt parts 0;
  target = builtins.elemAt parts 1;

  platforms = {
    arm = {
      bits = 32;
      endian = "little";
      family = "arm";
    };
    armv5tel = {
      bits = 32;
      endian = "little";
      family = "arm";
      version = "5";
      arch = "armv5t";
    };
    armv6m = {
      bits = 32;
      endian = "little";
      family = "arm";
      version = "6";
      arch = "armv6-m";
    };
    armv6l = {
      bits = 32;
      endian = "little";
      family = "arm";
      version = "6";
      arch = "armv6";
    };
    armv7a = {
      bits = 32;
      endian = "little";
      family = "arm";
      version = "7";
      arch = "armv7-a";
    };
    armv7r = {
      bits = 32;
      endian = "little";
      family = "arm";
      version = "7";
      arch = "armv7-r";
    };
    armv7m = {
      bits = 32;
      endian = "little";
      family = "arm";
      version = "7";
      arch = "armv7-m";
    };
    armv7l = {
      bits = 32;
      endian = "little";
      family = "arm";
      version = "7";
      arch = "armv7";
    };
    armv8a = {
      bits = 32;
      endian = "little";
      family = "arm";
      version = "8";
      arch = "armv8-a";
    };
    armv8r = {
      bits = 32;
      endian = "little";
      family = "arm";
      version = "8";
      arch = "armv8-a";
    };
    armv8m = {
      bits = 32;
      endian = "little";
      family = "arm";
      version = "8";
      arch = "armv8-m";
    };
    aarch64 = {
      bits = 64;
      endian = "little";
      family = "arm";
      version = "8";
      arch = "armv8-a";
    };
    aarch64_be = {
      bits = 64;
      endian = "big";
      family = "arm";
      version = "8";
      arch = "armv8-a";
    };

    i386 = {
      bits = 32;
      endian = "little";
      family = "x86";
      arch = "i386";
    };
    i486 = {
      bits = 32;
      endian = "little";
      family = "x86";
      arch = "i486";
    };
    i586 = {
      bits = 32;
      endian = "little";
      family = "x86";
      arch = "i586";
    };
    i686 = {
      bits = 32;
      endian = "little";
      family = "x86";
      arch = "i686";
    };
    x86_64 = {
      bits = 64;
      endian = "little";
      family = "x86";
      arch = "x86-64";
    };

    microblaze = {
      bits = 32;
      endian = "big";
      family = "microblaze";
    };
    microblazeel = {
      bits = 32;
      endian = "little";
      family = "microblaze";
    };

    mips = {
      bits = 32;
      endian = "big";
      family = "mips";
    };
    mipsel = {
      bits = 32;
      endian = "little";
      family = "mips";
    };
    mips64 = {
      bits = 64;
      endian = "big";
      family = "mips";
    };
    mips64el = {
      bits = 64;
      endian = "little";
      family = "mips";
    };

    mmix = {
      bits = 64;
      endian = "big";
      family = "mmix";
    };

    m68k = {
      bits = 32;
      endian = "big";
      family = "m68k";
    };

    powerpc = {
      bits = 32;
      endian = "big";
      family = "power";
    };
    powerpc64 = {
      bits = 64;
      endian = "big";
      family = "power";
    };
    powerpc64le = {
      bits = 64;
      endian = "little";
      family = "power";
    };
    powerpcle = {
      bits = 32;
      endian = "little";
      family = "power";
    };

    riscv32 = {
      bits = 32;
      endian = "little";
      family = "riscv";
    };
    riscv64 = {
      bits = 64;
      endian = "little";
      family = "riscv";
    };

    s390 = {
      bits = 32;
      endian = "big";
      family = "s390";
    };
    s390x = {
      bits = 64;
      endian = "big";
      family = "s390";
    };

    sparc = {
      bits = 32;
      endian = "big";
      family = "sparc";
    };
    sparc64 = {
      bits = 64;
      endian = "big";
      family = "sparc";
    };

    wasm32 = {
      bits = 32;
      endian = "little";
      family = "wasm";
    };
    wasm64 = {
      bits = 64;
      endian = "little";
      family = "wasm";
    };

    alpha = {
      bits = 64;
      endian = "little";
      family = "alpha";
    };

    rx = {
      bits = 32;
      endian = "little";
      family = "rx";
    };
    msp430 = {
      bits = 16;
      endian = "little";
      family = "msp430";
    };
    avr = {
      bits = 8;
      family = "avr";
    };

    vc4 = {
      bits = 32;
      endian = "little";
      family = "vc4";
    };

    or1k = {
      bits = 32;
      endian = "big";
      family = "or1k";
    };

    loongarch64 = {
      bits = 64;
      endian = "little";
      family = "loongarch";
    };

    javascript = {
      bits = 32;
      endian = "little";
      family = "javascript";
    };
  };
in {
  options.aux.platform = {
    name = lib.options.create {
      type = lib.types.string;
      description = "Name of the platform";
    };

    family = lib.options.create {
      type = lib.types.string;
      description = "Family of the platform";
    };

    bits = lib.options.create {
      type = lib.types.int;
      description = "Number of bits in the platform";
    };

    endian = lib.options.create {
      type = lib.types.enum ["little" "big"];
      default.value = "big";
      description = "Endianess of the platform";
    };

    arch = lib.options.create {
      type = lib.types.nullish lib.types.string;
      default.value = null;
      description = "Architecture of the platform";
    };

    version = lib.options.create {
      type = lib.types.nullish lib.types.string;
      default.value = null;
      description = "Version of the platform";
    };

    build = lib.options.create {
      type = lib.types.string;
      description = "The build entry, such as x86-unknown-linux-gnu.";
    };

    host = lib.options.create {
      type = lib.types.string;
      description = "The host entry, such as x86-unknown-linux-gnu.";
    };
  };

  config = {
    aux.platform =
      (
        platforms.${platform}
        or (builtins.throw "Unsupported platform: ${system}")
      )
      // {
        name = platform;

        # These will only ever have `linux` as the target since we
        # do not support darwin bootstrapping.
        build = "${platform}-unknown-${target}-gnu";
        host = "${platform}-unknown-${target}-gnu";
      };
  };
}
