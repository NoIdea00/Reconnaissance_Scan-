# 🛰️ Recon Scanner - Automated Subdomain & Path Discovery

A comprehensive Bash-based reconnaissance scanner that combines the power of multiple subdomain enumeration tools and optional path fuzzing with `ffuf`. This tool automates domain recon and saves organized results for every run.

## 🔧 Features

- 🔎 Subdomain enumeration using:
  - `sublist3r`
  - `subdominator`
  - `subfinder`
  - `amass`
- 📁 Merges and deduplicates subdomains into `subdomains.txt`
- 🚀 Optional directory fuzzing with `ffuf`
- 📦 Structured timestamped result folders for each scan
- 📝 Automatically generates a scan summary report

## 📚 Requirements

- `bash`
- `sublist3r`, `subdominator`, `subfinder`, `amass`
- `ffuf` (optional)
- A valid wordlist (default path is set inside the script)

## 💾 Installation

```bash
git clone https://github.com/NoIdea00/Reconnaissance_Scan-.git
cd recon-scan-tool
chmod +x recon-scan.sh
```

## 🚀 Usage

### Scan a single domain
```bash
./recon-scan.sh example.com
```

### Scan multiple domains from a file
```bash
./recon-scan.sh -f domains.txt
```

The script will ask whether to run `ffuf` during the scan.

## 📂 Output Directory Structure

```
results/
└── example.com/
    └── 20250515_1532/
        ├── amass_output.txt
        ├── subfinder_output.txt
        ├── sublist3r_output.txt
        ├── subdominator_output.txt
        ├── subdomains.txt
        ├── ffuf_discovered_paths.txt (if selected)
        └── scan_summary.txt
```

## 🧪 Example

```bash
./recon-scan.sh -f mydomains.txt
```

## 📃 License

MIT License

---

### 🙌 Contributions

No Thanks!

