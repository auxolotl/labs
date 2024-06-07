{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.tinycc.boot;

  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
  cflags = stage1.mes.libc.package.extras.CFLAGS;

  createBoot = {
    pname,
    version,
    src,
  }: let
    compiler = builders.kaem.build {
      name = "${pname}-${version}";

      script = ''
        catm config.h
        ${stage1.mes.compiler.package}/bin/mes --no-auto-compile -e main ${stage1.mes.libs.src.bin}/bin/mescc.scm -- \
          -S \
          -o tcc.s \
          -I . \
          -D BOOTSTRAP=1 \
          -I ${src} \
          -D TCC_TARGET_I386=1 \
          -D inline= \
          -D CONFIG_TCCDIR=\"\" \
          -D CONFIG_SYSROOT=\"\" \
          -D CONFIG_TCC_CRTPREFIX=\"{B}\" \
          -D CONFIG_TCC_ELFINTERP=\"/mes/loader\" \
          -D CONFIG_TCC_LIBPATHS=\"{B}\" \
          -D CONFIG_TCC_SYSINCLUDEPATHS=\"${stage1.mes.libc.package}/include\" \
          -D TCC_LIBGCC=\"${stage1.mes.libc.package}/lib/x86-mes/libc.a\" \
          -D CONFIG_TCC_LIBTCC1_MES=0 \
          -D CONFIG_TCCBOOT=1 \
          -D CONFIG_TCC_STATIC=1 \
          -D CONFIG_USE_LIBGCC=1 \
          -D TCC_MES_LIBC=1 \
          -D TCC_VERSION=\"${version}\" \
          -D ONE_SOURCE=1 \
          ${src}/tcc.c
        mkdir -p ''${out}/bin
        ${stage1.mes.compiler.package}/bin/mes --no-auto-compile -e main ${stage1.mes.libs.src.bin}/bin/mescc.scm -- \
          -L ${stage1.mes.libs.package}/lib \
          -l c+tcc \
          -o ''${out}/bin/tcc \
          tcc.s
      '';
    };

    libs = createLibc {
      inherit pname version;
      src = stage1.mes.libc.package;
      args = cflags;
      tinycc = compiler;
    };
  in {inherit compiler libs;};

  createTinyccMes = {
    pname,
    version,
    src,
    args,
    boot,
    lib ? {},
    meta,
  }: let
    compiler = builders.kaem.build {
      name = "${pname}-${version}";

      inherit meta;

      #
      script = ''
        catm config.h
        mkdir -p ''${out}/bin
        ${boot.compiler}/bin/tcc \
          -B ${boot.libs}/lib \
          -g \
          -v \
          -o ''${out}/bin/tcc \
          -D BOOTSTRAP=1 \
          ${builtins.concatStringsSep " " args} \
          -I . \
          -I ${src} \
          -D TCC_TARGET_I386=1 \
          -D CONFIG_TCCDIR=\"\" \
          -D CONFIG_SYSROOT=\"\" \
          -D CONFIG_TCC_CRTPREFIX=\"{B}\" \
          -D CONFIG_TCC_ELFINTERP=\"\" \
          -D CONFIG_TCC_LIBPATHS=\"{B}\" \
          -D CONFIG_TCC_SYSINCLUDEPATHS=\"${stage1.mes.libc.package}/include\" \
          -D TCC_LIBGCC=\"libc.a\" \
          -D TCC_LIBTCC1=\"libtcc1.a\" \
          -D CONFIG_TCCBOOT=1 \
          -D CONFIG_TCC_STATIC=1 \
          -D CONFIG_USE_LIBGCC=1 \
          -D TCC_MES_LIBC=1 \
          -D TCC_VERSION=\"${version}\" \
          -D ONE_SOURCE=1 \
          ${src}/tcc.c
      '';
    };

    libs = createLibc {
      inherit pname version src;

      args =
        builtins.concatStringsSep
        " "
        (
          ["-c" "-D" "TCC_TARGET_I386=1"]
          ++ (lib.args or [])
        );

      tinycc = compiler;
    };
  in {
    inherit compiler libs boot;
  };

  createLibc = {
    pname,
    version,
    src,
    args,
    tinycc,
  }: let
    createLibrary = name: args: source:
      builders.kaem.build {
        name = "${name}.a";

        script = ''
          ${tinycc}/bin/tcc ${args} -c -o ${name}.o ${source}
          ${tinycc}/bin/tcc -ar cr ''${out} ${name}.o
        '';
      };

    crt = builders.kaem.build {
      name = "crt";

      script = ''
        mkdir -p ''${out}/lib
        ${tinycc}/bin/tcc ${cflags} -c -o ''${out}/lib/crt1.o ${stage1.mes.libc.package}/lib/crt1.c
        ${tinycc}/bin/tcc ${cflags} -c -o ''${out}/lib/crtn.o ${stage1.mes.libc.package}/lib/crtn.c
        ${tinycc}/bin/tcc ${cflags} -c -o ''${out}/lib/crti.o ${stage1.mes.libc.package}/lib/crti.c
      '';
    };

    libtcc1 = createLibrary "libtcc1" args "${src}/lib/libtcc1.c";
    libc = createLibrary "libc" cflags "${stage1.mes.libc.package}/lib/libc.c";
    libgetopt = createLibrary "libgetopt" cflags "${stage1.mes.libc.package}/lib/libgetopt.c";
  in
    builders.kaem.build {
      name = "${pname}-libs-${version}";

      script = ''
        mkdir -p ''${out}/lib
        cp ${crt}/lib/crt1.o ''${out}/lib
        cp ${crt}/lib/crtn.o ''${out}/lib
        cp ${crt}/lib/crti.o ''${out}/lib
        cp ${libtcc1} ''${out}/lib/libtcc1.a
        cp ${libc} ''${out}/lib/libc.a
        cp ${libgetopt} ''${out}/lib/libgetopt.a
      '';
    };
in {
  inherit
    createBoot
    createTinyccMes
    createLibc
    ;
}
