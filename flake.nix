{
  description = "Kayak Hull Optimisation";

  inputs = {
    self.submodules = true;
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    hullopt.url = "./kayak-hull-optimisation";
  };

  outputs =
    {
      self,
      nixpkgs,
      hullopt,
      ...
    }:
    let
      system = "x86_64-linux";
      overrideOpenCV = self: super: {
        #opencv = super.opencv.overrideAttrs (old: {
        #  cmakeFlags = (old.cmakeFlags or []) ++ [
        #    "-DBUILD_TESTS=OFF"
        #  ];
        #});
      };
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ overrideOpenCV ];
      };
      pythonBase = pkgs.python311;
      python = pythonBase.override {
        packageOverrides = self: super: {
          numpy = super."numpy_1";
          paramz = super.paramz.overridePythonAttrs(_: {
            doCheck = false; # Hangs on lists_and_dictionaries tests
          });
          gpy = super.gpy.overridePythonAttrs(_: {
            doCheck = false; # Fails due to deprecation warning on MultioutputGP_gradobs_prod_mix test
          });
          pytest-doctestplus = super.pytest-doctestplus.overridePythonAttrs(_: {
            doCheck = false;
          });
          threadpoolctl = super.threadpoolctl.overridePythonAttrs(_: {
            version = "3.1.0";
            src = super.fetchPypi {
              pname = "threadpoolctl";
              version = "3.1.0";
              sha256 = "sha256-ozW6rPqkQArh8NjjpY1mdNL4go43FrsoAsRJVa05E4A=";
            };
          });
          pywavelets = super.pywavelets.overridePythonAttrs(_: {
            version = "1.8.0";
            src = super.fetchPypi {
              pname = "pywavelets";
              version = "1.8.0";
              sha256 = "sha256-84ACRXVIQK3BQ8vClTShuPxLjP9unUAzJr1St7tcNao=";
            };

            postPatch = ''
              substituteInPlace pyproject.toml --replace "numpy>=2.0.0" "numpy"
            '';

            buildSystem = with python.pkgs; [
              meson-python
              cython
            ];
          });
          pyerfa = super.pyerfa.overridePythonAttrs(_: {
            version = "2.0.1.4";
            src = super.fetchPypi {
              pname = "pyerfa";
              version = "2.0.1.4";
              sha256 = "sha256-rLimcTIy6jXAS8bkCsTkYd/MgX05XvKjyAUcGjMkndM=";
            };

            postPatch = ''
              substituteInPlace pyproject.toml --replace "numpy>=2.0.0rc1" "numpy"
            '';
          });
          astropy = super.astropy.overridePythonAttrs(_: {
            version = "6.1.4";
            pyproject = true;
            src = super.fetchPypi {
              pname = "astropy";
              version = "6.1.4";
              sha256 = "sha256-NhVY4rCTqZvr5p8f1H+shqGSYHpMFu05ugqACyq2DDQ=";
            };

            postPatch = ''
              substituteInPlace pyproject.toml --replace "numpy>=2.0.0" "numpy"
            '';
          });
          statsmodels = super.statsmodels.overridePythonAttrs(_: {
            postPatch = ''
              substituteInPlace pyproject.toml --replace "numpy<3,>=2.0.0" "numpy"
            '';
          });
          numcodecs = super.numcodecs.overridePythonAttrs(_: {
            version = "0.10.0";
            src = super.fetchPypi {
              pname = "numcodecs";
              version = "0.10.0";
              sha256 = "sha256-LdQlZOd3KpOFkjsCo2Pjzt8FPOkwlKkGRIXn9ppvHJI=";
            };

            #postPatch = ''
            #  substituteInPlace pyproject.toml --replace "numpy>=2" "numpy"
            #'';
          });
            scikit-learn = python.pkgs.buildPythonPackage rec {
            version = "1.5.2";
            pname = "scikit_learn";
            pyproject = true;

            src = python.pkgs.fetchPypi {
              inherit pname version;
              sha256 = "sha256-tCN+17P90KSIJ5LmjvJUXVuqUKyju0WqffRoE4rY+U0=";
            };


            buildInputs = with python.pkgs; [
              numpy.blas
              pillow
            ];

            nativeBuildInputs = [
              #nixpkgs.gfortran
            ];

            build-system = with python.pkgs; [
              cython
              meson-python
              numpy
              scipy
            ];

            dependencies = with python.pkgs; [
              joblib
              numpy
              scipy
              threadpoolctl
            ];

            postPatch = ''
              substituteInPlace pyproject.toml \
                --replace-fail "numpy>=2" "numpy"

              substituteInPlace meson.build --replace-fail \
                "run_command('sklearn/_build_utils/version.py', check: true).stdout().strip()," \
                "'${version}',"
            '';

            doCheck = false;
          };
        };
      };



      pyfoam = python.pkgs.buildPythonPackage rec {
        pname = "PyFoam";
        version = "2023.7";
        format = "wheel";
        src = python.pkgs.fetchPypi {
          inherit pname version format;
          sha256 = "sha256-qLCM7hnwqD+OuTl2OBOfMQWX16W89FBatjoGl/YNFFY=";
        };
      };

      mpl_axes_aligner = python.pkgs.buildPythonPackage rec {
        pname = "mpl_axes_aligner";
        version = "1.3";
        src = python.pkgs.fetchPypi {
          inherit pname version;
          sha256 = "sha256-/fWvxaVAlDBCdFrzAGO0ir4BM30pAzJpXufSE1bkF2g=";
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
      };
    in
    {
      devShells."${system}".default = pkgs.mkShell {
        buildInputs = with pkgs; [
          opencv
        ];

        packages = with pkgs; [
          just
          libGL
          libGLU
          xorg.libX11
          xorg.libXext
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
              shapely
              networkx
              rtree
              mpl_axes_aligner
              gpy
              scikit-learn
              pandas
              customtkinter
              # optuna # Disabled due to memory leaks or excessive memory usage from some if it's dependencies
              # Use pip instead
              pip
              virtualenv
            ]
          ))
          pyright
        ];

        # TODO: Package project in editable mode rather than using PYTHONPATH
        shellHook = ''
          	  export PYTHONPATH=${toString ./kayak-hull-optimisation}:$PYTHONPATH

              if [ ! -d .venv ]; then
                python -m venv .venv
              fi
              source .venv/bin/activate
          	'';
      };
    };
}
