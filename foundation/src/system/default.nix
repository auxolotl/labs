{lib}: {
  options.aux = {
    system = lib.options.create {
      type = lib.types.string;
      description = ''
        The system to build packages for. This value can be provided as either
        `config.aux.system` or by setting the `system` argument for modules.
      '';
    };
  };
}
