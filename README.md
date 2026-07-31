<div align="center">

# 🧅 Tor ML

## 🌍 Multi Tor Location Manager

**Run multiple isolated Tor instances on a single server with an interactive terminal dashboard.**

<br>

![Bash](https://img.shields.io/badge/Shell-Bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)
![Tor](https://img.shields.io/badge/Network-Tor-7D4698?style=for-the-badge&logo=torproject&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Linux-Ubuntu%20%7C%20Debian-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)

<br>

🌍 **50 Locations** • 🔐 **Isolated Nodes** • ⚡ **Lightweight** • 🎛 **CLI Control**

</div>

---

# 🧅 Overview

**Tor ML** is a lightweight Bash-based Tor instance manager that allows you to run multiple independent Tor nodes on a single Linux server.

Each node runs separately with:

- ⚙️ Dedicated configuration
- 📂 Separate data directory
- 📜 Individual logs
- 🔌 Unique SOCKS port

Designed for simplicity:

- ✅ No Web Panel
- ✅ No Heavy Dependencies
- ✅ Fast Terminal Management

---

# ✨ Features

| Feature | Description |
|---|---|
| 🌍 Multi Location | 50 predefined Tor exit locations |
| 🔐 Isolation | Separate Tor process per node |
| 🔌 SOCKS Manager | Dedicated local SOCKS ports |
| 📊 Dashboard | CPU / RAM monitoring |
| ▶️ Control | Start and stop locations |
| 🚀 Bulk Actions | Start or stop all nodes |
| 🔄 Port Manager | Change SOCKS ports |
| ⚡ Speed Test | Latency and connection testing |
| 📜 Logs | Separate logs per instance |
| 🧹 Cleanup | Complete uninstall |

---

# 📦 Requirements

| Item | Requirement |
|---|---|
| 🖥 OS | Ubuntu / Debian |
| 👑 Access | Root Access |
| 🧑‍💻 User | root / sudo |
| ⚙️ CPU | 1 Core+ |
| 🧠 RAM | 512MB+ Recommended |
| 💾 Storage | 1GB+ Free Space |
| 🏗 Architecture | x86_64 |

Required packages:

```
tor
tor-geoipdb
curl
bc
```

---

# ⚡ Installation

## 📥 Download

```bash
curl -fsSL https://raw.githubusercontent.com/icubaby/Tor-ML/main/tor-ml.sh -o tor-ml.sh
```

## 🚀 Install

```bash
sudo bash tor-ml.sh --install
```

## 🎛 Run Dashboard

```bash
tor
```

---

# 🎛 Interactive Menu

| Key | Action |
|:---:|---|
| `1` | 📊 Full Status |
| `2` | ▶️ Start Location |
| `3` | ⏹ Stop Location |
| `4` | 🚀 Start All Nodes |
| `5` | 🛑 Stop All Nodes |
| `6` | 🔄 Change SOCKS Port |
| `7` | ⚡ Speed Test |
| `8` | 🗑 Uninstall |
| `0` | 🚪 Exit |

---

# 🌍 Supported Locations

Tor ML includes **50 predefined Tor exit locations**:

| ID | Code | Location | Port |
|:--:|:--:|---|:--:|
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

# 🔌 SOCKS Configuration

Default SOCKS port range:

```
48180 - 48229
```

Listen address:

```
127.0.0.1
```

Example:

```
127.0.0.1:48180
```

---

# 🔢 Multiple Selection

Supported formats:

```
1.4.12
```

```
1,4,12
```

```
1 4 12
```

---

# 🌍 Xray Integration

## 🔌 SOCKS Outbound

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

---

## 🛣 Routing Rule

Send selected inbound traffic through Tor:

```json
{
  "type": "field",
  "inboundTag": [
    "your-inbound-tag"
  ],
  "outboundTag": "tor-node"
}
```

---

## 🧪 Test Connection

```bash
curl --socks5 127.0.0.1:48180 https://api.ipify.org
```

---

# 📁 Directory Structure

```
/opt/tor-ml

├── config     ⚙️ Tor configurations
├── data       📂 Runtime data
├── logs       📜 Instance logs
└── status     📊 Node status
```

---

# 🔒 Security

- 🔐 SOCKS ports listen only on localhost
- 👤 Runs with unprivileged `debian-tor` user
- 🚫 Default Tor service disabled
- 🧩 Every node runs independently
- 🌐 No public SOCKS exposure

---

# 🗑 Uninstall

From menu:

```
8 → Uninstall
```

Manual:

```bash
sudo pkill -f "node_.*_48"

sudo rm -rf /opt/tor-ml

sudo rm -f /usr/local/bin/tor
```

---

# ⚠ Disclaimer

This project is provided for educational and research purposes only.

The author is not responsible for misuse, illegal activities, or damages caused by this software.

Use responsibly.

---

# 📄 License

MIT License © 2026

</div>
