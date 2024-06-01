lib: {
  math = {
    # TODO: Document this.
    min = x: y:
      if x < y
      then x
      else y;

    # TODO: Document this.
    max = x: y:
      if x > y
      then x
      else y;
  };
}
