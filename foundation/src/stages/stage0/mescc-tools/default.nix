{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage0.mescc-tools;
  hex0 = config.aux.foundation.stages.stage0.hex0;
  catm = config.aux.foundation.stages.stage0.catm;
  M0 = config.aux.foundation.stages.stage0.M0;
  cc_arch = config.aux.foundation.stages.stage0.cc_arch;
  M2 = config.aux.foundation.stages.stage0.M2;
  blood-elf = config.aux.foundation.stages.stage0.blood-elf;
  M1 = config.aux.foundation.stages.stage0.M1;
  hex2 = config.aux.foundation.stages.stage0.hex2;
  kaem-unwrapped = config.aux.foundation.stages.stage0.kaem-unwrapped;

  system = config.aux.system;
  builders = config.aux.foundation.builders;
  sources = config.aux.foundation.stages.stage0.sources;
  architecture = config.aux.foundation.stages.stage0.architecture;

  bloodFlag =
    if config.aux.platform.bits == 64
    then "--64"
    else " ";
  endianFlag =
    if config.aux.platform.endian == "little"
    then "--little-endian"
    else "--big-endian";
  baseAddress =
    if config.aux.system == "x86_64-linux"
    then "0x00600000"
    else if config.aux.system == "aarch64-linux"
    then "0x00600000"
    else if config.aux.system == "i686-linux"
    then "0x08048000"
    else builtins.throw "Unsupported system: ${config.aux.system}";

  getExtraUtil = name: let
    script = builtins.toFile "build-${name}.kaem" ''
        ''${M2} --architecture ${architecture.m2libc} \
        -f ''${m2libc}/sys/types.h \
        -f ''${m2libc}/stddef.h \
        -f ''${m2libc}/${architecture.m2libc}/linux/fcntl.c \
        -f ''${m2libc}/fcntl.c \
        -f ''${m2libc}/${architecture.m2libc}/linux/unistd.c \
        -f ''${m2libc}/${architecture.m2libc}/linux/sys/stat.c \
        -f ''${m2libc}/stdlib.c \
        -f ''${m2libc}/stdio.h \
        -f ''${m2libc}/stdio.c \
        -f ''${m2libc}/string.c \
        -f ''${m2libc}/bootstrappable.c \
        -f ''${mesccToolsExtra}/${name}.c \
        --debug \
        -o ${name}.M1

      ''${blood-elf-0} ${endianFlag} ${bloodFlag} -f ${name}.M1 -o ${name}-footer.M1

      ''${M1} --architecture ${architecture.m2libc} \
        ${endianFlag} \
        -f ''${m2libc}/${architecture.m2libc}/${architecture.m2libc}_defs.M1 \
        -f ''${m2libc}/${architecture.m2libc}/libc-full.M1 \
        -f ${name}.M1 \
        -f ${name}-footer.M1 \
        -o ${name}.hex2

      ''${hex2} --architecture ${architecture.m2libc} \
        ${endianFlag} \
        -f ''${m2libc}/${architecture.m2libc}/ELF-${architecture.m2libc}-debug.hex2 \
        -f ${name}.hex2 \
        --base-address ${baseAddress} \
        -o ''${out}

    '';
  in
    builders.raw.build {
      pname = "mescc-tools-extra-${name}";
      version = "1.6.0";

      meta = cfg.meta;

      executable = kaem-unwrapped.package;

      args = [
        "--verbose"
        "--strict"
        "--file"
        script
      ];

      src = sources.base;

      M1 = M1.package;
      M2 = M2.package;
      blood-elf-0 = blood-elf.package;
      hex2 = hex2.package;

      m2libc = sources.m2libc;
      m2planet = sources.m2planet;
      m2mesoplanet = sources.m2mesoplanet;
      mesccTools = sources.mescc-tools;
      mesccToolsExtra = sources.mescc-tools-extra;

      bloodFlag = bloodFlag;
      endianFlag = endianFlag;
      baseAddress = baseAddress;
    };
in {
  options.aux.foundation.stages.stage0.mescc-tools = {
    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "Collection of tools for use in bootstrapping.";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://github.com/oriansj/stage0-posix";
      };

      license = lib.options.create {
        # TODO: Add a proper type for licenses.
        type = lib.types.attrs.any;
        description = "License for the package.";
        default.value = lib.licenses.gpl3Plus;
      };

      platforms = lib.options.create {
        type = lib.types.list.of lib.types.string;
        description = "Platforms the package supports.";
        default.value = ["i686-linux"];
      };
    };

    package = lib.options.create {
      type = lib.types.derivation;
      description = "The package to use for mescc-tools.";
    };
  };

  config = {
    aux.foundation.stages.stage0.mescc-tools = {
      package = lib.modules.overrides.default (builders.raw.build {
        pname = "mescc-tools";
        version = "1.6.0";

        meta = cfg.meta;

        executable = kaem-unwrapped.package;

        args = [
          "--verbose"
          "--strict"
          "--file"
          ./build.kaem
        ];

        M1 = M1.package;
        M2 = M2.package;
        blood-elf-0 = blood-elf.package;
        hex2 = hex2.package;

        m2libc = sources.m2libc;
        m2libcArch = architecture.m2libc;
        m2planet = sources.m2planet;
        m2mesoplanet = sources.m2mesoplanet;
        mesccTools = sources.mescc-tools;
        mesccToolsExtra = sources.mescc-tools-extra;

        bloodFlag = bloodFlag;
        endianFlag = endianFlag;
        baseAddress = baseAddress;

        mkdir = getExtraUtil "mkdir";
        cp = getExtraUtil "cp";
        chmod = getExtraUtil "chmod";
        replace = getExtraUtil "replace";
      });
    };
  };
}
