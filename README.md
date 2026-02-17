# Apocalyptic Inconvenience

A 3D first-person survival/horror game set in a gas station on a remote desert planet. Work your shift, serve customers, keep the place running — and figure out which visitors are human before it's too late.

**DDU Eksamensprojekt**

## Premise

You play as a gas station attendant stranded at a lonely outpost in the desert. Customers come and go throughout the day, but not all of them are what they seem. Some are ordinary travellers. Others are horrific mutations — skinwalker-like creatures disguised as people — who will turn violent if you let your guard down. Your job is to keep the station running, serve real customers, and identify the imposters before they get to you.

## Core Gameplay

### Customer Interaction
- Customers arrive throughout the day and approach the station
- Each customer has randomized dialogue pulled from a hardcoded pool of lines and responses
- You can ask customers questions: where they're headed, where they came from, what they need, etc.
- Customers respond with branching dialogue — their answers may reveal whether they're genuine or not
- Bad actors (mutations) will attempt to kill you after enough interaction if you don't identify and deal with them first

### Identification System
- A **checklist** is available to help you spot imposters based on observable traits:
  - Are they wearing sandals?
  - Do they have a hat on (contextual — depends on time of day)?
  - Skin colour abnormalities (green skin, odd textures, etc.)
  - Behavioural tells in dialogue (contradictions, strange responses)
- A **radio** broadcasts daily reports including:
  - Missing persons cases — a described individual may show up at your station
  - Warnings about sightings or dangerous activity in the area
  - Clues that tie into the customers you'll encounter that day

### Gas Station Management
- **Restocking shelves** — items fall or run out and need to be replaced from the warehouse
- **Pest control** — rats, insects, and other critters invade the station; kick them away or they'll knock products off shelves and create messes
- **Cleaning up** — spills and knocked-over items need to be tidied
- **Gas pumps** — help customers fuel up at the pumps outside
- **Warehouse** — the back storage area where supplies are kept; retrieve stock to refill the shelves

### Survival
- Survive day by day by balancing station duties with threat identification
- Failing to spot a mutation can result in a deadly encounter
- Neglecting the station (messy shelves, unattended pumps, pest infestations) has consequences

## Key Features

| Feature | Description |
|---|---|
| **Day/Night Cycle** | Time progresses through each shift; lighting, customer frequency, and threat level change accordingly |
| **Randomized Customers** | Each customer is generated with random dialogue sets, appearance traits, and a chance of being a mutation |
| **Dialogue System** | Hardcoded dialogue trees with branching responses; different questions yield different information |
| **Radio Broadcasts** | Daily reports with missing persons, warnings, and clues to help identify threats |
| **Identification Checklist** | Observable criteria to cross-reference against each customer |
| **Station Tasks** | Restocking, cleaning, pest control, and pump assistance keep you busy between customers |
| **Warehouse** | Back storage area for retrieving supplies to restock the shop floor |
| **Pest System** | Rats and insects that disrupt the station if left unchecked |
| **Threat Encounters** | Mutations that escalate to violence if not identified and handled |

## Tech Stack

- **Engine:** Godot 4.5 (Forward Plus renderer)
- **Language:** GDScript
- **Perspective:** First-person 3D

## Target Audience

Teens and high schoolers — the game blends horror and responsibility mechanics to create an engaging experience around running a workplace while staying alert under pressure.
