<div align="center">

# 🧅 **Tor ML**  
## 🌍 *Multi Tor Location Manager*

**Run multiple isolated Tor instances on a single server with an interactive terminal dashboard.**

<br>

![Bash](https://img.shields.io/badge/Shell-Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)
![Tor](https://img.shields.io/badge/Network-Tor-7D4698?style=for-the-badge&logo=torproject&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Linux-Ubuntu%20%7C%20Debian-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)

<br>

🌍 **50 Locations** &nbsp;•&nbsp; 🔐 **Isolated Nodes** &nbsp;•&nbsp; ⚡ **Lightweight** &nbsp;•&nbsp; 🎛 **CLI Control** &nbsp;•&nbsp; 📊 **v2 Dashboard**

</div>

---

## 📖 Overview

**Tor ML** is a lightweight Bash‑based Tor instance manager that lets you run **multiple independent Tor nodes** on a single Linux server.  
Each node runs completely isolated with its own configuration, data directory, logs, SOCKS port, and real‑time metrics.

### 🚀 Key Highlights

- ⚙️ **Dedicated config** per node  
- 📂 **Separate data directory**  
- 📜 **Individual logs**  
- 🔌 **Unique SOCKS port**  
- 📈 **Per‑node CPU / RAM / Uptime / IP tracking**  
- 🚦 **Bandwidth limiting** support  

Designed for simplicity:

- ✅ No Web Panel  
- ✅ No Heavy Dependencies  
- ✅ Fast Terminal Management  

---

## ✨ Features at a Glance

| Feature | Description |
|---------|-------------|
| 🌍 **Multi Location** | 50 predefined Tor exit locations |
| 🔐 **Isolation** | Separate Tor process per node |
| 🔌 **SOCKS Manager** | Dedicated local SOCKS ports |
| 📊 **Advanced Dashboard** | CPU / RAM / SOCKS / Bootstrap / Uptime / IP |
| ▶️ **Control** | Start and stop individual locations |
| 🚀 **Bulk Actions** | Start or stop all nodes at once |
| 🔄 **Port Manager** | Change SOCKS ports on the fly |
| ⚡ **Speed Test** | Latency and connection testing |
| 📜 **View Log** | Show last 20 lines of any node log |
| 📶 **Bandwidth Control** | Limit bandwidth per location (MB) |
| 🧹 **Cleanup** | Complete uninstall with one command |
| ⚙️ **Settings System** | Unified `settings.db` with auto‑migration |

---

## 📦 System Requirements

| Item | Requirement |
|------|-------------|
| 🖥 **OS** | Ubuntu / Debian (or compatible) |
| 👑 **Access** | Root or `sudo` privileges |
| 🧑‍💻 **User** | root / sudo |
| ⚙️ **CPU** | 1 Core+ |
| 🧠 **RAM** | 512MB+ (recommended) |
| 💾 **Storage** | 1GB+ free space |
| 🏗 **Architecture** | x86_64 |

### Required Packages

```bash
tor tor-geoipdb curl bc netcat-openbsd
```

---

## ⚡ Installation

### 📥 Download the Script

```bash
curl -fsSL https://raw.githubusercontent.com/icubaby/Tor-ML/main/tor-ml.sh -o tor-ml.sh
```

### 🚀 Run the Installer

```bash
sudo bash tor-ml.sh --install
```

### 🎛 Launch the Dashboard

After installation, simply run:

```bash
tor
```

---

## 🎛 Interactive Menu

| Key | Action |
|:---:|--------|
| `1` | 📊 **Full Status** – show all nodes |
| `2` | ▶️ **Start Location** – choose a node |
| `3` | ⏹ **Stop Location** – stop a node |
| `4` | 🚀 **Start All Nodes** |
| `5` | 🛑 **Stop All Nodes** |
| `6` | 🔄 **Change SOCKS Port** |
| `7` | ⚡ **Speed Test** |
| `8` | 📜 **View Log** – last 20 lines |
| `9` | 📶 **Set Bandwidth** (MB) |
| `10` | 🗑 **Uninstall** – complete removal |
| `0` | 🚪 **Exit** |

---

## 🌍 Supported Locations

Tor ML includes **50 predefined Tor exit locations** with automatic port assignment:

| # | Code | Location | Port |
|:-:|:----:|----------|:----:|
| 01 | DE | Germany | 48180 |
| 02 | TR | Turkey | 48181 |
| 03 | US | United States | 48182 |
| 04 | FR | France | 48183 |
| 05 | AT | Austria | 48184 |
| 06 | BE | Belgium | 48185 |
| 07 | RO | Romania | 48186 |
| 08 | CA | Canada | 48187 |
| 09 | SG | Singapore | 48188 |
| 10 | JP | Japan | 48189 |
| 11 | IE | Ireland | 48190 |
| 12 | FI | Finland | 48191 |
| 13 | ES | Spain | 48192 |
| 14 | PL | Poland | 48193 |
| 15 | NL | Netherlands | 48194 |
| 16 | IT | Italy | 48195 |
| 17 | CH | Switzerland | 48196 |
| 18 | SE | Sweden | 48197 |
| 19 | NO | Norway | 48198 |
| 20 | DK | Denmark | 48199 |
| 21 | IS | Iceland | 48200 |
| 22 | AU | Australia | 48201 |
| 23 | IN | India | 48202 |
| 24 | HK | Hong Kong | 48203 |
| 25 | UA | Ukraine | 48204 |
| 26 | CZ | Czech Republic | 48205 |
| 27 | KR | South Korea | 48206 |
| 28 | ZA | South Africa | 48207 |
| 29 | MX | Mexico | 48208 |
| 30 | MY | Malaysia | 48209 |
| 31 | AZ | Azerbaijan | 48210 |
| 32 | CY | Cyprus | 48211 |
| 33 | GR | Greece | 48212 |
| 34 | PT | Portugal | 48213 |
| 35 | HU | Hungary | 48214 |
| 36 | LU | Luxembourg | 48215 |
| 37 | GB | United Kingdom | 48216 |
| 38 | AR | Argentina | 48217 |
| 39 | TW | Taiwan | 48218 |
| 40 | BG | Bulgaria | 48219 |
| 41 | IL | Israel | 48220 |
| 42 | MD | Moldova | 48221 |
| 43 | RU | Russia | 48222 |
| 44 | CL | Chile | 48223 |
| 45 | CR | Costa Rica | 48224 |
| 46 | VN | Vietnam | 48225 |
| 47 | ID | Indonesia | 48226 |
| 48 | SC | Seychelles | 48227 |
| 49 | HR | Croatia | 48228 |
| 50 | TN | Tunisia | 48229 |

---

## 🔌 SOCKS Configuration

- **Default port range:** `48180 – 48229`  
- **Listen address:** `127.0.0.1` (localhost only)

Example SOCKS5 proxy:

```
127.0.0.1:48180
```

---

## 🔢 Multiple Selection Format

When prompted for location numbers, you can use:

- **Range:** `1.4.12`  
- **Comma‑separated:** `1,4,12`  
- **Space‑separated:** `1 4 12`

---

## 📶 Bandwidth Control

Limit bandwidth per location (in MB/s):

- `0` = unlimited (default)
- Recommended values: `5`, `10`, `20`, `50`, `100`

Bandwidth is applied via Tor’s `BandwidthRate` and `BandwidthBurst`.  
> **Note:** Changes take effect after restarting the node.

---

## 🌍 Xray / V2Ray Integration

### 🔌 SOCKS Outbound Example

```json
{
  "tag": "tor-node",
  "protocol": "socks",
  "settings": {
    "servers": [
      {
        "address": "127.0.0.1",
        "port": 48180
      }
    ]
  }
}
```

### 🛣 Routing Rule

Send selected inbound traffic through Tor:

```json
{
  "type": "field",
  "inboundTag": ["your-inbound-tag"],
  "outboundTag": "tor-node"
}
```

### 🧪 Test the Connection

```bash
curl --socks5 127.0.0.1:48180 https://api.ipify.org
```

---

## 📁 Directory Structure

```
/opt/tor-ml
├── 📁 config/                   # ⚙️  Configuration files
│   ├── 🗄️  settings.db          # Unified settings (port, bandwidth, uptime)
│   └── 📄 node_XX_PORT.conf    # Per‑node Tor configuration files
├── 📂 data/                     # 💾 Runtime data directories (one per node)
├── 📜 logs/                     # 📝 Instance logs
└── 🏷️ status/                   # 📊 Cached IP & status files
```

---

## 🔒 Security

- 🔐 SOCKS ports bind to `127.0.0.1` only  
- 👤 Runs with unprivileged `debian-tor` user  
- 🚫 Default Tor service is disabled  
- 🧩 Every node runs independently  
- 🌐 No public SOCKS exposure  
- 🛡️ `SocksPolicy` accepts only `127.0.0.1` and rejects everything else

---

## 🗑 Uninstall

### From the Menu

```
10 → Uninstall
```

### Manual Removal

```bash
sudo pkill -f "node_.*\.conf"
sudo rm -rf /opt/tor-ml
sudo rm -f /usr/local/bin/tor
```

---

## 💖 Support the Project

If you find **Tor ML** useful, consider supporting its continued development.  
Every contribution helps keep the project alive and improving!

| Network | Address |
|---------|---------|
| **BEP-20** (BSC) | `0x404fb6f281443c7f9e420a5dc96c2592ae1be3d2` |
| **TON** (The Open Network) | `UQDA9l1hEI4Vn8krfx0K1kTVBCudcSqxn8w0Tgcf1ZNne9A4` |

> ⚠️ **Important:** Please double-check the network before sending any funds.  
> Only send BEP-20 tokens to the BSC address and TON coins to the TON address.

---

## ⚠ Disclaimer

This project is provided for **educational and research purposes only**.  
The author is not responsible for misuse, illegal activities, or damages caused by this software.  
**Use responsibly.**

---

## 📄 License

MIT License © 2026

