{
  description = "A very basic flake";

  outputs = _: {
    lib = import ./src;
  };
}
