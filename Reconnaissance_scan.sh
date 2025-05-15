#!/bin/bash

# Tools
TOOLS=("sublist3r" "subdominator" "subfinder" "amass")
WORDLIST="/home/kali/Desktop/Web Scanning Tools/Recon Scan/wordlists/SecLists-master/Discovery/Web-Content/combined_directories.txt"

# Colors
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

# Help menu
show_help() {
  echo -e "${BLUE}Usage: $0 [options] <domain | -f file>${RESET}"
  echo "Options:"
  echo "  -f <file>     Recon multiple domains from file"
  echo "  -h, --help    Display help"
  echo "Example:"
  echo "  $0 example.com"
  echo "  $0 -f domains.txt"
}

# Directory
create_directory() {
  DOMAIN=$1
  TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
  BASE_DIR="results/${DOMAIN}/${TIMESTAMP}"
  mkdir -p "$BASE_DIR"
  cd "$BASE_DIR" || exit
}

# Subdomain Enumeration Functions
run_tool() {
  TOOL=$1
  DOMAIN=$2
  OUT="${TOOL}_output.txt"
  echo -e "${YELLOW}Running $TOOL on $DOMAIN...${RESET}"

  if ! command -v "$TOOL" &>/dev/null; then
    echo "$TOOL not installed." > "$OUT"
    return
  fi

  case $TOOL in
    sublist3r) sublist3r -d "$DOMAIN" -b -v -o "$OUT" ;;
    subdominator) subdominator -d "$DOMAIN" -o "$OUT" ;;
    amass) amass enum -d "$DOMAIN" -o "$OUT" ;;
    subfinder) subfinder -d "$DOMAIN" -o "$OUT" ;;
  esac
}

merge_subdomains() {
  DOMAIN=$1
  cat *_output.txt 2>/dev/null | grep -Ei "^([a-zA-Z0-9_\-]+\.)+$DOMAIN$" | sort -u > subdomains.txt
  echo -e "${GREEN}Subdomains saved to subdomains.txt${RESET}"
}

# FFUF
run_ffuf() {
  DOMAIN=$1
  FFUF_RESULTS=()
  echo -e "${YELLOW}Running ffuf on discovered subdomains...${RESET}"

  while IFS= read -r sub; do
    [[ -z "$sub" ]] && continue
    echo -e "${BLUE}Fuzzing $sub...${RESET}"
    OUT="ffuf_${sub//[:\/]/_}.txt"
    ffuf -w "$WORDLIST" -u "http://$sub/FUZZ" -o "$OUT" -of simple &>/dev/null
    MATCHES=$(grep -oP "http://$sub/\S+" "$OUT")
    [[ -n "$MATCHES" ]] && FFUF_RESULTS+=("$MATCHES")
  done < subdomains.txt

  echo "${FFUF_RESULTS[@]}" > ffuf_discovered_paths.txt
}

# Summary
generate_summary() {
  DOMAIN=$1
  SUMMARY="scan_summary.txt"
  DATE_FMT=$(date +"%B %d, %Y, %H:%M:%S")
  DIR_NAME=$(pwd)

  echo -e "${GREEN}Generating summary...${RESET}"
  {
    echo "Scan Summary for $DOMAIN"
    echo "Timestamp: $DATE_FMT"
    echo "Results saved in: $DIR_NAME"
    echo
    echo "Discovered Subdomains:"
    cat subdomains.txt
    echo
    echo "Total Subdomains Found: $(wc -l < subdomains.txt)"
    echo "Sources Used:"
    for tool in "${TOOLS[@]}"; do
      [[ -f "${tool}_output.txt" && -s "${tool}_output.txt" ]] && echo "  - $tool ✔" || echo "  - $tool ✘"
    done
    echo
    echo "Fuzzing (ffuf):"
    if [[ "$RUN_FFUF" == true ]]; then
      echo "Status: ✅ Performed"
      echo "Wordlist Used: $WORDLIST"
      echo "Example Fuzzed Hosts:"
      head -n 2 subdomains.txt | sed 's/^/  - http:\/\//' 
      echo
      echo "Discovered Paths:"
      [[ -f ffuf_discovered_paths.txt ]] && cat ffuf_discovered_paths.txt | sed 's/^/  - /' || echo "  - No paths found"
    else
      echo "Status: ❌ Skipped"
    fi
  } > "$SUMMARY"

  echo -e "${GREEN}Summary written to $SUMMARY${RESET}"
}

# Run Recon
run_recon() {
  DOMAIN=$1
  create_directory "$DOMAIN"
  for tool in "${TOOLS[@]}"; do
    run_tool "$tool" "$DOMAIN"
  done
  merge_subdomains "$DOMAIN"
  if [[ "$RUN_FFUF" == true ]]; then
    run_ffuf "$DOMAIN"
  fi
  generate_summary "$DOMAIN"
}

# Batch
batch_scan() {
  FILE=$1
  while IFS= read -r domain; do
    [[ -n "$domain" ]] && run_recon "$domain"
  done < "$FILE"
}

# Start of script logic
while [[ "$1" =~ ^- ]]; do
  case $1 in
    -h|--help) show_help; exit 0 ;;
    -f) BATCH_FILE=$2; shift ;;
    *) show_help; exit 1 ;;
  esac
  shift
done

if [[ -z "$1" && -z "$BATCH_FILE" ]]; then
  echo -e "${RED}Please provide a domain or use -f <file>.${RESET}"
  show_help
  exit 1
fi

# Ask user about FFUF
read -rp "Do you want to run ffuf fuzzing? [y/N]: " FFUF_ANS
[[ "$FFUF_ANS" =~ ^[Yy]$ ]] && RUN_FFUF=true || RUN_FFUF=false

# Run scan
if [[ -n "$BATCH_FILE" ]]; then
  batch_scan "$BATCH_FILE"
else
  run_recon "$1"
fi
