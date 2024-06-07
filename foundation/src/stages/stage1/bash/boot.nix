{
  lib,
  config,
}: let
  cfg = config.aux.foundation.stages.stage1.bash.boot;

  builders = config.aux.foundation.builders;

  stage1 = config.aux.foundation.stages.stage1;
in {
  options.aux.foundation.stages.stage1.bash.boot = {
    package = lib.options.create {
      type = lib.types.package;
      description = "The package to use for bash-boot.";
    };

    meta = {
      description = lib.options.create {
        type = lib.types.string;
        description = "Description for the package.";
        default.value = "GNU Bourne-Again Shell, the de facto standard shell on Linux";
      };

      homepage = lib.options.create {
        type = lib.types.string;
        description = "Homepage for the package.";
        default.value = "https://www.gnu.org/software/bash";
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
        default.value = ["x86_64-linux" "aarch64-linux" "i686-linux"];
      };
    };

    version = lib.options.create {
      type = lib.types.string;
      description = "Version of the package.";
    };

    src = lib.options.create {
      type = lib.types.package;
      description = "Source for the package.";
    };
  };

  config = {
    aux.foundation.stages.stage1.bash.boot = {
      version = "2.05b";

      src = builtins.fetchurl {
        url = "https://ftpmirror.gnu.org/bash/bash-${cfg.version}.tar.gz";
        sha256 = "1r1z2qdw3rz668nxrzwa14vk2zcn00hw7mpjn384picck49d80xs";
      };

      package = let
        # Thanks to the live-bootstrap project!
        # See https://github.com/fosslinux/live-bootstrap/blob/1bc4296091c51f53a5598050c8956d16e945b0f5/sysa/bash-2.05b/bash-2.05b.kaem
        liveBootstrap = "https://github.com/fosslinux/live-bootstrap/raw/1bc4296091c51f53a5598050c8956d16e945b0f5/sysa/bash-2.05b";

        main_mk = builtins.fetchurl {
          url = "${liveBootstrap}/mk/main.mk";
          sha256 = "0hj29q3pq3370p18sxkpvv9flb7yvx2fs96xxlxqlwa8lkimd0j4";
        };

        common_mk = builtins.fetchurl {
          url = "${liveBootstrap}/mk/common.mk";
          sha256 = "09rigxxf85p2ybnq248sai1gdx95yykc8jmwi4yjx389zh09mcr8";
        };

        builtins_mk = builtins.fetchurl {
          url = "${liveBootstrap}/mk/builtins.mk";
          sha256 = "0939dy5by1xhfmsjj6w63nlgk509fjrhpb2crics3dpcv7prl8lj";
        };

        patches = [
          # mes libc does not have locale support
          (builtins.fetchurl {
            url = "${liveBootstrap}/patches/mes-libc.patch";
            sha256 = "0zksdjf6zbb3p4hqg6plq631y76hhhgab7kdvf7cnpk8bcykn12z";
          })
          # int name, namelen; is wrong for mes libc, it is char* name, so we modify tinycc
          # to reflect this.
          (builtins.fetchurl {
            url = "${liveBootstrap}/patches/tinycc.patch";
            sha256 = "042d2kr4a8klazk1hlvphxr6frn4mr53k957aq3apf6lbvrjgcj2";
          })
          # add ifdef's for features we don't want
          (builtins.fetchurl {
            url = "${liveBootstrap}/patches/missing-defines.patch";
            sha256 = "1q0k1kj5mrvjkqqly7ki5575a5b3hy1ywnmvhrln318yh67qnkj4";
          })
          # mes libc + setting locale = not worky
          (builtins.fetchurl {
            url = "${liveBootstrap}/patches/locale.patch";
            sha256 = "1p1q1slhafsgj8x4k0dpn9h6ryq5fwfx7dicbbxhldbw7zvnnbx9";
          })
          # We do not have /dev at this stage of the bootstrap, including /dev/tty
          (builtins.fetchurl {
            url = "${liveBootstrap}/patches/dev-tty.patch";
            sha256 = "1315slv5f7ziajqyxg4jlyanf1xwd06xw14y6pq7xpm3jzjk55j9";
          })
        ];
      in
        builders.kaem.build {
          name = "bash-${cfg.version}";

          meta = cfg.meta;
          src = cfg.src;

          deps.build.host = [
            stage1.tinycc.mes.compiler.package
            stage1.gnumake.package
            stage1.gnupatch.package
            stage1.coreutils.boot.package
          ];

          script = ''
            # Unpack
            ungz --file ${cfg.src} --output bash.tar
            untar --file bash.tar
            rm bash.tar
            cd bash-${cfg.version}

            # Patch
            ${lib.strings.concatMapSep "\n" (file: "patch -Np0 -i ${file}") patches}

            # Configure
            cp ${main_mk} Makefile
            cp ${builtins_mk} builtins/Makefile
            cp ${common_mk} common.mk
            touch config.h
            touch include/version.h
            touch include/pipesize.h

            # Build
            make \
              CC="tcc -B ${stage1.tinycc.mes.libs.package}/lib" \
              mkbuiltins
            cd builtins
            make \
              CC="tcc -B ${stage1.tinycc.mes.libs.package}/lib" \
              libbuiltins.a
            cd ..
            make CC="tcc -B ${stage1.tinycc.mes.libs.package}/lib"

            # Install
            install -D bash ''${out}/bin/bash
            ln -s bash ''${out}/bin/sh
          '';
        };
    };
  };
}
