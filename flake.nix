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
      python = pkgs.python311;
      pyfoam = python.pkgs.buildPythonPackage rec {
        pname = "PyFoam";
        version = "2023.7";
        format = "wheel";
        src = python.pkgs.fetchPypi {
          inherit pname version format;
          sha256 = "sha256-qLCM7hnwqD+OuTl2OBOfMQWX16W89FBatjoGl/YNFFY=";
        };
      };
      pyglet1 = python.pkgs.buildPythonPackage rec {
        pname = "pyglet";
        version = "1.4.2";
        src = python.pkgs.fetchPypi {
          inherit pname version;
          sha256 = "sha256-/aJa5emQV/Bb0znqeXIZbS9E5v6PshCVGrAfZgnNvbc=";
        };

        # Patch the libraries being loaded
        postPatch = with pkgs; ''
          cat > pyglet/lib.py <<EOF
          import ctypes
          def load_library(*names, **kwargs):
            for name in names:
              path = None
              match name:
                case "GL": path = "${libGL}/lib/libGL.so"
                case "GLU": path = "${libGLU}/lib/libGLU.so"
                case "X11": path = "${xorg.libX11}/lib/libX11.so"
                case "Xext": path = "${xorg.libXext}/lib/libXext.so"
                case _:
                  raise Exception("Could not load library {}".format(names))
              
              print("loading: " + name)
              return ctypes.cdll.LoadLibrary(path)
          EOF
        '';

        #postPatch = ''
        #
        #  echo "Directories:"
        #  find . -maxdepth 4 -type d -print
        #  echo "Python files:"
        #  find . -maxdepth 6 -name "*.py" -print
        #  exit 1
        #'';
      };
    in
    {
      devShells."${system}".default = pkgs.mkShell {
        packages = with pkgs; [
          just
          libGL
          libGLU
          xorg.libX11
          (python.withPackages (
            p: with p; [
              future
              numpy
              pyfoam
              matplotlib
              autopep8
              trimesh
              pyglet1
              typing
              manifold3d
              scipy
            ]
          ))
          pyright
        ];

        shellHook = '''';
      };
    };
}
