import tempfile
from pathlib import Path
from cibuildwheel.platforms import macos as platform

def main():
    configs = platform.all_python_configurations()
    with tempfile.TemporaryDirectory() as tmp_root:
        for config in configs:
            tmp = Path(tmp_root) / config.identifier
            tmp.mkdir(exist_ok=True)
            implementation_id = config.identifier.split("-")[0]
            if implementation_id.startswith("cp"):
                free_threading = "t-macos" in config.identifier
                base_python = platform.install_cpython(
                    tmp, config.version, config.url, free_threading
                )

            elif implementation_id.startswith("pp"):
                base_python = platform.install_pypy(tmp, config.url)
            elif implementation_id.startswith("gp"):
                base_python = platform.install_graalpy(tmp, config.url)
 

if __name__ == "__main__":
    main()
