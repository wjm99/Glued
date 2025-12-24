<p align="center"><img width="128" height="128" alt="1" src="https://github.com/user-attachments/assets/b7471931-9e9d-46c2-893a-c69c16850962" /></p>


<h1 align="center">Glued</h1>

<div align="center">

[![Release](https://img.shields.io/github/v/release/wjm99/Glued)](https://github.com/wjm99/Glued/releases)
![Swift](https://img.shields.io/badge/language-Swift-orange)
[![Issues](https://img.shields.io/github/issues/wjm99/Glued)](https://github.com/wjm99/Glued/issues)

</div>

**Glued** is designed to solve the one-way AirPods connection issue between macOS and iOS devices.

**Glued** is a tiny (2.3MB) macOS menu bar app that keeps your AirPods (AirPods Pro, AirPods Max) connected to Mac **while audio is playing**, and lets macOS auto‑switch normally when audio stops. 

If you’re tired of your AirPods randomly switching to your iPhone or iPad in the middle of work — this is for you.

Glued supports both **Intel** and **Apple Silicon** Macs.

👉 Download on Gumroad:
https://jinming5.gumroad.com/l/glued

<img width="4864" height="2938" alt="MacBook Pro 14" src="https://github.com/user-attachments/assets/0dc98f53-c817-4ded-9fc6-5d3798361e1b" />

---

## What It Does

* 📌 Keeps your selected Bluetooth audio device *“glued”* to your Mac while audio is playing
* 🔁 Allows normal Apple auto‑switching behavior when audio stops
* 🎧 Works with AirPods, AirPods Pro and AirPods Max
* 🧩 Runs quietly in the menu bar
* ⚡ Lightweight, no background services, no ads

---

## Installation

1. Download the latest release from the **Releases** page
2. Open `Glued.app`
3. Grant Bluetooth permission when prompted
4. Connect your AirPods and select them in Glued

---

## Permissions

### Bluetooth Access (Required)

Glued needs **Bluetooth permission** to:

* Detect connected Bluetooth audio devices
* Keep the selected device connected while audio is playing

macOS will prompt you for Bluetooth access on first launch.
Please allow it for Glued to work correctly.

> Glued does **not** collect data, track devices, or communicate over the network.

---

## Requirements

* macOS 13(Ventura) or later
* Bluetooth audio device (AirPods, AirPods Pro, AirPods Max)

---

## Acknowledgements

This project is inspired by [blueutil](https://github.com/toy/blueutil) and [switchaudio](https://github.com/deweller/switchaudio-osx).

It also makes use of the following Apple frameworks:
- CoreAudio
- IOBluetooth
- AudioToolbox
