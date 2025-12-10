{
  description = "Kayak Hull Optimisation";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      python = pkgs.python39;
      pyfoam = python.pkgs.buildPythonPackage rec {
        pname = "PyFoam";
        version = "2023.7";
        format = "wheel";
        src = python.pkgs.fetchPypi {
          inherit pname version format;
          sha256 = "sha256-qLCM7hnwqD+OuTl2OBOfMQWX16W89FBatjoGl/YNFFY=";
        };
      };
    in
    {
      devShells."${system}".default = pkgs.mkShell {
        packages = with pkgs; [
          just
          (python.withPackages (
            p: with p; [
              numpy
              pyfoam
              matplotlib
              autopep8
            ]
          ))
          pyright
        ];

        shellHook = '''';
      };
    };
}
