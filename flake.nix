{
  description = "Automatically make ic() from icecream available";

  outputs = { self, nixpkgs, flake-utils }:
    let
      deps = pyPackages: with pyPackages; [
        icecream
        pytest
      ];
      tools = pkgs: pyPackages: (with pyPackages; [
        pytestCheckHook
        mypy pytest-mypy
      ] ++ [pkgs.ruff]);

      pytest-icecream-package = {pkgs, python3Packages}:
        python3Packages.buildPythonPackage {
          pname = "pytest-icecream";
          version = "0.0.1";
          src = ./.;
          format = "pyproject";
          propagatedBuildInputs = deps python3Packages;
          nativeBuildInputs = [ python3Packages.setuptools ];
          outputs = [ "out" "testout" ];
          postInstall = ''
            mkdir $testout
            cp -R tests $testout/tests
            cp pyproject.toml $testout/
          '';
        };

      pytest-icecream-tests = {pkgs, python3Packages}:
        python3Packages.buildPythonPackage {
          pname = "pytest-icecream-tests";
          inherit (python3Packages.pytest-icecream) version;
          format = "other";
          src = python3Packages.pytest-icecream.testout;
          dontBuild = true;
          dontInstall = true;
          nativeBuildInputs = deps python3Packages;
          checkInputs = tools pkgs python3Packages ++ [
            python3Packages.pytest-icecream
          ];
          prePatch = "find";
          checkPhase = "pytest -v";
        };

      overlay = final: prev: {
        pythonPackagesExtensions =
          prev.pythonPackagesExtensions ++ [(pyFinal: pyPrev: {
            pytest-icecream = final.callPackage pytest-icecream-package {
              python3Packages = pyFinal;
            };
          })];
      };

      overlay-tests = final: prev: {
        pythonPackagesExtensions =
          prev.pythonPackagesExtensions ++ [(pyFinal: pyPrev: {
            pytest-icecream-tests = final.callPackage pytest-icecream-tests {
              python3Packages = pyFinal;
            };
          })];
      };

      overlay-all = nixpkgs.lib.composeManyExtensions [
        overlay
        overlay-tests
      ];

    in
      flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = import nixpkgs { inherit system; overlays = [ overlay-all ]; };
          defaultPython3Packages = pkgs.python311Packages;  # force 3.11
        in
        {
          devShells.default = pkgs.mkShell {
            buildInputs = [(defaultPython3Packages.python.withPackages deps)];
            nativeBuildInputs = tools pkgs defaultPython3Packages;
            shellHook = ''
              export PYTHONASYNCIODEBUG=1 PYTHONWARNINGS=error
            '';
          };
          packages = {
            inherit (defaultPython3Packages)
              pytest-icecream pytest-icecream-tests;
            default = defaultPython3Packages.pytest-icecream;
          };
        }
    ) // { overlays.default = overlay; };
}
