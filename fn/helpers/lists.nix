{ lib }:
{
  allUnique = values: builtins.length values == builtins.length (lib.unique values);
}
