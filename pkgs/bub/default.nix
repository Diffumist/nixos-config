{
  lib,
  fetchFromGitHub,
  fetchPypi,
  python3Packages,
  makeWrapper,
  bash,
  git,
  uv,
  ...
}:

let
  py = python3Packages;

  openresponses-types = py.buildPythonPackage rec {
    pname = "openresponses-types";
    version = "2.3.0.post1";
    pyproject = true;

    src = fetchPypi {
      pname = "openresponses_types";
      inherit version;
      hash = "sha256-EbiJbTYh0qwkOfb/EG803csbvVF8MXpshSqd8umKB1M=";
    };

    build-system = [ py.hatchling ];
    dependencies = [ py.pydantic ];

    pythonImportsCheck = [ "openresponses_types" ];
  };

  any-llm-sdk = py.buildPythonPackage rec {
    pname = "any-llm-sdk";
    version = "1.13.0";
    pyproject = true;

    src = fetchPypi {
      pname = "any_llm_sdk";
      inherit version;
      hash = "sha256-lnxfTdCZ9fbMlnPyiI1VUPboIdJTQdMRM6BXQcHOkD4=";
    };

    build-system = [ py.setuptools ];
    dependencies = [
      py.anthropic
      py.httpx
      py.openai
      openresponses-types
      py.pydantic
      py.rich
      py.typing-extensions
    ];

    pythonImportsCheck = [ "any_llm" ];
  };

  inquirer-textual = py.buildPythonPackage rec {
    pname = "inquirer-textual";
    version = "0.5.1";
    pyproject = true;

    src = fetchPypi {
      pname = "inquirer_textual";
      inherit version;
      hash = "sha256-TkYEowO6WOcyHZYES6I1szMvLzMLCBKCkUvlBOH1nHE=";
    };

    build-system = [ py.hatchling ];
    dependencies = [ py.textual ];

    pythonImportsCheck = [ "inquirer_textual" ];
  };

  republic = py.buildPythonPackage rec {
    pname = "republic";
    version = "0.5.8";
    pyproject = true;

    src = fetchPypi {
      inherit pname version;
      hash = "sha256-S4o8rUUIBVfH00tJz9LV0k0Bqro10nrBmjv1EGdLd+U=";
    };

    build-system = [ py.hatchling ];
    dependencies = [
      any-llm-sdk
      py.authlib
      py.httpx
      py.pydantic
    ];

    pythonImportsCheck = [ "republic" ];
  };
in
py.buildPythonApplication rec {
  pname = "bub";
  version = "0.3.0+unstable.2026.05.27";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "bubbuild";
    repo = "bub";
    rev = "42125122f0eb2b55449be1d8105b6399f25295a6";
    hash = "sha256-BMTXAl2nSxV6mqDcoJipUhl4NdpgI4RHtAjTjrbprzU=";
  };

  build-system = [
    py.hatchling
    py.hatch-vcs
  ];

  nativeBuildInputs = [ makeWrapper ];

  dependencies = [
    py.aiohttp
    any-llm-sdk
    py.httpx
    py.socksio
    inquirer-textual
    py.loguru
    py.pluggy
    py.prompt-toolkit
    py.pydantic
    py.pydantic-settings
    py.python-telegram-bot
    py.pyyaml
    py.rapidfuzz
    republic
    py.rich
    py.typer
  ];

  postFixup = ''
    wrapProgram $out/bin/bub \
      --prefix PATH : ${
        lib.makeBinPath [
          bash
          git
          uv
        ]
      }
  '';

  pythonImportsCheck = [ "bub" ];

  meta = {
    description = "A common shape for agents that live alongside people";
    homepage = "https://github.com/bubbuild/bub";
    license = lib.licenses.asl20;
    mainProgram = "bub";
    platforms = lib.platforms.linux;
  };
}
