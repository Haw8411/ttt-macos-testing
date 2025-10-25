#!/bin/bash
# MacInfoAndInstall.command
# Shows hardware info ONLY after you type 'Y', then installs Firefox, Chrome, and LibreOffice via macapps.link

set -euo pipefail
export PATH="/usr/sbin:/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin"

########################################
# Utility: Fetch and print hardware info
########################################
print_hardware_info() {
  echo "=========================="
  echo "   Mac Hardware Summary"
  echo "=========================="

  # Get hardware info once
  local HW_TEXT
  HW_TEXT="$(system_profiler SPHardwareDataType || true)"

  # Serial Number
  local serial
  serial="$(echo "$HW_TEXT" | awk -F': ' '/Serial Number/{print $2; exit}')"
  if [[ -z "${serial:-}" ]]; then
    serial="$(ioreg -l | awk -F\" '/IOPlatformSerialNumber/{print $4; exit}')"
  fi

  # Model Name / Identifier
  local model_name model_id
  model_name="$(echo "$HW_TEXT" | awk -F': ' '/Model Name/{print $2; exit}')"
  model_id="$(echo "$HW_TEXT" | awk -F': ' '/Model Identifier/{print $2; exit}')"

  # CPU / Chip (Apple Silicon shows 'Chip', Intel shows 'Processor Name')
  local chip cpu_brand cpu_sku
  chip="$(echo "$HW_TEXT" | awk -F': ' '/^ *Chip:|^ *Processor Name:/{print $2; exit}')"
  cpu_brand="$(sysctl -n machdep.cpu.brand_string 2>/dev/null || true)"
  if [[ -n "${cpu_brand:-}" && "$cpu_brand" != "Apple processor" ]]; then
    cpu_sku="$cpu_brand"
  else
    cpu_sku="$chip"
  fi

  # Resolve human-friendly model and year via Apple (requires internet)
  local model_readable device_year
  model_readable=""
  device_year=""
  if [[ -n "${serial:-}" ]]; then
    # Example XML element: <configCode>MacBook Pro (14-inch, 2023)</configCode>
    local apple_xml
    apple_xml="$(curl -fsSL "https://support-sp.apple.com/sp/product?serial=${serial}" || true)"
    model_readable="$(printf "%s" "$apple_xml" | grep -o "<configCode>[^<]*</configCode>" | sed -E 's#</?configCode>##g' | head -n1 || true)"
    device_year="$(printf "%s" "$model_readable" | grep -oE '[0-9]{4}' | head -n1 || true)"
  fi

  echo "Model:            ${model_name:-Unknown} (${model_id:-Unknown})"
  if [[ -n "${model_readable:-}" ]]; then
    echo "Model (Apple):    ${model_readable}"
  fi
  echo "Year:             ${device_year:-Unknown}"
  echo "Serial Number:    ${serial:-Unknown}"
  echo "CPU SKU:          ${cpu_sku:-Unknown}"
  echo
}

########################################
# Installer: macapps.link bundle
########################################
run_install() {
  echo "=========================="
  echo "   Installing Applications"
  echo "=========================="
  echo "This will install: Firefox, Chrome, LibreOffice"
  echo
  # NOTE: You are piping a remote script into the shell. Only run this if you trust the source.
  curl -fsSL 'https://api.macapps.link/en/firefox-chrome-libreoffice' | sh
  echo
  echo "Install complete."
  echo
}

########################################
# Main flow
########################################

echo "This script will display your hardware information and then install:"
echo "  - Firefox"
echo "  - Chrome"
echo "  - LibreOffice"
echo
read -r -p "Type Y to show the hardware info and continue with installation (anything else to abort): " CONFIRM
if [[ "${CONFIRM:-}" != "Y" ]]; then
  echo "Aborted by user."
  echo
  read -r -p "Press Return to close..." _
  exit 1
fi

run_install
print_hardware_info

read -r -p "Press Return to close..." _
