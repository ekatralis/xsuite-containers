from pathlib import Path
import shutil
import re
import numpy as np

# -------------------------
# User settings
# -------------------------
source_file = Path("sim_params.py")      # template file to copy
output_list = Path("scan_dirs.txt")      # txt file with relative folder paths

# Bunch intensity scan
delta_bint = 0.3e12
bunch_intensity_scan = np.arange(0.1e12, 2.3e12, delta_bint)

print("Bunch intensity scan:", bunch_intensity_scan)

# -------------------------
# Helpers
# -------------------------
def folder_name_from_value(value: float) -> str:
    return f"bunchmonitor_with_bellows_bint_{value:.2e}"

def set_bunch_intensity_in_file(filepath: Path, value: float) -> None:
    """
    Replace an existing `bunch_intensity = ...` line if present.
    Otherwise append it at the end of the file.
    """
    text = filepath.read_text()

    new_line = f"bunch_intensity = {value:.1f}\n"

    pattern = r"(?m)^\s*bunch_intensity\s*=\s*.*$"
    if re.search(pattern, text):
        text = re.sub(pattern, new_line.strip(), text)
    else:
        if not text.endswith("\n"):
            text += "\n"
        text += "\n# Added by scan setup script\n" + new_line

    filepath.write_text(text)

# -------------------------
# Main
# -------------------------
if not source_file.exists():
    raise FileNotFoundError(f"Template file not found: {source_file}")

relative_paths = []

for value in bunch_intensity_scan:
    folder = Path(folder_name_from_value(value))
    folder.mkdir(parents=True, exist_ok=True)

    dst_file = folder / source_file.name
    shutil.copy2(source_file, dst_file)

    set_bunch_intensity_in_file(dst_file, value)

    relative_paths.append(folder.as_posix())

# Write folder list for HTCondor
output_list.write_text("\n".join(relative_paths) + "\n")

print(f"Created {len(relative_paths)} folders")
print(f"Wrote folder list to: {output_list}")
