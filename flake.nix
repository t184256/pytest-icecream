{
  description = "Automatically make ic() from icecream available";

  outputs = { self, nixpkgs, flake-utils }:
    let
      pyDeps = pyPackages: with pyPackages; [
        icecream
        pytest
      ];
      pyTestDeps = pyPackages: with pyPackages; [
        pytest pytestCheckHook
      ];
      pyTools = pyPackages: with pyPackages; [ mypy ];

      tools = pkgs: with pkgs; [
        pre-commit
        ruff
        codespell
        actionlint
        python3Packages.pre-commit-hooks
      ];

      pytest-icecream-package = {pkgs, python3Packages}:
        python3Packages.buildPythonPackage {
          pname = "pytest-icecream";
          version = "0.0.1";
          src = ./.;
          disabled = python3Packages.pythonOlder "3.11";
          format = "pyproject";
          build-system = [ python3Packages.setuptools ];
          propagatedBuildInputs = pyDeps python3Packages;
          checkInputs = pyTestDeps python3Packages;
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
          nativeBuildInputs = pyDeps python3Packages;
          checkInputs =
            pyDeps python3Packages ++ pyTestDeps python3Packages ++ [
              python3Packages.pytest-icecream
            ];
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
            buildInputs = [(defaultPython3Packages.python.withPackages (
              pyPkgs: pyDeps pyPkgs ++ pyTestDeps pyPkgs ++ pyTools pyPkgs
            ))];
            nativeBuildInputs = [(pkgs.buildEnv {
              name = "pytest-icecream-tools-env";
              pathsToLink = [ "/bin" ];
              paths = tools pkgs;
            })];
            shellHook = ''
              [ -e .git/hooks/pre-commit ] || \
                echo "suggestion: pre-commit install --install-hooks" >&2
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
