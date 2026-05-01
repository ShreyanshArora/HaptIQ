# 📱 HaptIQ – Feel the Game

HaptIQ is a **multiplayer social deduction game** that uses **haptic feedback (vibrations)** as the core gameplay mechanic.  
Instead of relying on visuals, players must **trust what they feel** to identify the imposter.

---

## 🎮 Game Concept

In HaptIQ, players join a room and are secretly assigned roles:

- 🟥 **Imposter** → Receives **no haptic feedback**
- 🟦 **Players (Civilians)** → Receive a **vibration clue**

The twist?  
The imposter must **blend in without any clue** and survive elimination.

---

## ⚡ Features

- 🎯 Unique Haptic-Based Gameplay  
- 👥 Multiplayer Room System (Local)  
- 🔐 Secret Role Assignment  
- 📳 CoreHaptics Integration  
- 🗳 Voting & Elimination System  
- 🎨 Custom UI + Animations  
- 🎭 Avatar Selection  
- 🚀 Fast Game Flow (No Cloud Required)  

---

## 🧠 Gameplay Flow

1. Create or join a room  
2. Enter name and select avatar  
3. Roles are assigned secretly  
4. Players receive haptic clues (imposter gets none)  
5. Discussion begins  
6. Imposter attempts to guess the clue  
7. If failed → voting round starts  
8. Players eliminate the suspected imposter  
9. Game ends with winner reveal  

---

## 🛠 Tech Stack

- **Language:** Swift  
- **Framework:** UIKit  
- **Architecture:** MVC  
- **Haptics:** CoreHaptics  
- **Animations:** PNG Sequence / UIKit Animations  
- **Storage:** Local (No backend)  

---

## 📂 Project Structure

```
HaptIQ/
│
├── Controllers/
│   ├── OnboardingController.swift
│   ├── CreateRoomViewController.swift
│   ├── JoinRoomViewController.swift
│   ├── AvatarSelectionController.swift
│   └── GameViewController.swift
│
├── Models/
│   ├── Player.swift
│   ├── Role.swift
│   └── GameManager.swift
│
├── Views/
│   ├── CustomComponents.swift
│
├── Resources/
│   ├── Images/
│   ├── Haptics/
│   └── Animations/
```

---

## 🎯 Key Highlights

- Designed a **non-visual gameplay mechanic** using haptics  
- Implemented **role-based feedback system**  
- Built **local multiplayer flow without backend**  
- Created **modular game architecture (GameManager)**  
- Focused on **UX, suspense, and interaction design**

---

## 🚀 Future Improvements

- 🔊 Add sound effects  
- 🌐 Online multiplayer support  
- 🧠 AI-based game balancing  
- 📊 Game analytics  

---

## ⭐ Tagline

> **“You can’t see the truth. You can only feel it.”**
