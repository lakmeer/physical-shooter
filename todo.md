
- Phone Interface
  - Add icons for the interface areas
  - Debug lack of graphics on iPhone
  - Add button states
  - Add title state with helper text
  - Change opacity on unavailable players

- Engine
  - IDD blast effect with restricted radius and it's own bin-space
  - Move to proper damage module
  - Introduce mass to force calculations

- Game flow
  - Add title screen when no players
  - Allow respawning
  - Wave histogram

- Wave Pod
  - Extract WavePod object, give it some agency
  - Points-buy system for waves
  - Stop restricting enemies to the screen box
  - Enemies attempt to move back towards the pod
  - Big enemies select nearest player, or player to hurt them most recently
  - Add enemy points-buy system

- Weapons
  - Go back to impact-based bullet damage
  - Floating weapon pickups
  - Add impact effect

- Force Weapons
  - Make collected strays increase charge
  - Add power cost to force weapons
  - Change laser power during falloff phase
  - Initialising a force weapon should cost more than running it for longer
    - Rapidly switching force weapons would cost twice as much as sustained use

- Optional
  - Add enemy luminance mapping and colored difficulty ranking
  - Add HUD with player, name, health, score and charge

