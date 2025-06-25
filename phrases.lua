-- phrases.lua
-- I dati delle frasi sono definiti direttamente come una tabella Lua nativa.
RaidCaller = RaidCaller or {}

RaidCaller.PhraseData = {
  ["Onyxia's Lair"] = {
    ["Onyxia"] = {
      ["Phrases"] = {
        "PHASE 1! Tank, position her facing the back wall. NOW!",
        "DPS and Healers, get to her sides! Do NOT stand in front or behind!",
        "WATCH THE TAIL! Don't get knocked into the whelps!",
        "PHASE 2! She's airborne! Spread out and prepare for Deep Breath!",
        "WATCH HER DIRECTION! Move to the safe zones NOW!",
        "Melee, focus on whelps! Ranged, burn the boss!",
        "PHASE 3! She's landing! Back to positions on the sides!",
        "FEAR INCOMING! Get your Tremor Totems down! Warriors, Berserker Rage!",
        "WATCH YOUR FEET! Get out of the fire cracks on the floor!"
      }
    }
  },
  ["Ruins of Ahn'Qiraj"] = {
    ["Kurinaxx"] = { ["Phrases"] = { "Tank, keep him faced away from the raid!", "Sand Traps are spawning! MOVE AWAY NOW! The explosion is huge!", "Off-tank, prepare to taunt! Main tank, let your debuff drop.", "ENRAGE at 30%! All DPS, burn him down!" } },
    ["General Rajaxx"] = { ["Phrases"] = { "Healers, keep our friendly NPCs alive! They are key!", "Tanks, backs to a wall! Prepare for the knockback!", "Waves incoming! CC any loose adds! Sheep, fear, root them!" } },
    ["Moam"] = { ["Phrases"] = { "MANA BURNERS! Drain his mana NOW! Stop the Arcane Eruption!", "He's turning to stone! Prepare for Mana Fiends!", "Warlocks, banish two fiends! DPS, focus fire the third one down!" } },
    ["Buru the Gorger"] = { ["Phrases"] = { "DPS, get all eggs to 10% health but DO NOT KILL them yet.", "Kiter, you're targeted! Lead Buru over a low-health egg!", "DPS, the egg is in position! KILL THE EGG NOW!", "ADD SPAWNED! Switch and kill the add immediately!", "ENRAGE at 20%! It's a burn phase! All cooldowns, GO!" } },
    ["Ayamiss the Hunter"] = { ["Phrases"] = { "PHASE 1 - AIR PHASE! Melee, your job is the larva! Kill it before it reaches the player!", "Ranged DPS with Nature Resist, you are soaking the Poison Stinger!", "ADD WAVES! They have low health, AOE them down fast!", "PHASE 2 - GROUND! She's landing! Tanks, pick her up! Face her away!" } },
    ["Ossirian the Unscarred"] = { ["Phrases"] = { "This is all about coordination! Stay focused!", "Puller, drag him to the first crystal! ACTIVATE!", "He's vulnerable! DPS, focus on the correct magic school!", "He cannot be taunted! Watch your threat! Tanks, use potions for the stun!" } }
  },
  ["Temple of Ahn'Qiraj"] = {
    ["The Prophet Skeram"] = { ["Phrases"] = { "Tank him in the center! Don't let him cast Earth Shock!", "INTERRUPT the Arcane Explosion!", "MIND CONTROL! Someone is big! Mages, Polymorph them NOW!", "HE'S SPLITTING! Groups, get to your assigned positions!", "Tanks, pick up the copies! DPS, burn the fakes down FAST!" } },
    ["The Bug Trio"] = { ["Phrases"] = { "Focus target is set! All DPS on the marked bug!", "DISPEL! Toxic Volley is out! Healers, cleanse the poison!", "Princess Yauj is fearing! Backup tank, be ready to taunt!", "INTERRUPT Yauj's heal!" } },
    ["Battleguard Sartura"] = { ["Phrases"] = { "EVERYONE SPREAD OUT! Don't get cleaved by Whirlwind!", "Tanks, pick up the adds and face them away! KILL ADDS FIRST!", "FIXATE! Sartura is loose! Taunt rotation, keep her still!", "They stopped spinning! STUN them now!" } },
    ["Fankriss the Unyielding"] = { ["Phrases"] = { "Tank swap! Mortal Wound stacks are high!", "PLAYER ENTANGLED! Healers, focus heals on them!", "WORMS ARE UP! All DPS, switch to worms NOW! Stun and kill them before they enrage!" } },
    ["Viscidus"] = { ["Phrases"] = { "PHASE 1: FREEZE! Hit him with Frost damage! Wands, oils, everything!", "HE'S FROZEN! PHASE 2: SHATTER! Melee, get in there and hit him NOW!", "HE'S SHATTERED! PHASE 3: DPS! Kill the globs before they reform!", "Engineers, prepare Sapper Charges for when they group up!" } },
    ["Princess Huhuran"] = { ["Phrases"] = { "Melee, you are soaking poison! Make sure your Nature Resist gear is on!", "Ranged and Healers, stay spread out to avoid Noxious Poison spread!", "DISPELLERS, only dispel Wyvern Sting on TANKS!", "FRENZY! Designated ranged, TRANQ SHOT NOW!", "ENRAGE at 30%! This is a pure DPS race! BURN HER!" } },
    ["The Twin Emperors"] = { ["Phrases"] = { "Keep them separated! They heal if they're too close!", "Melee on the magic-immune twin! Casters on the melee-immune twin!", "Warlock tanks, maintain threat on Vek'lor! Spam Searing Pain!", "TELEPORT INCOMING! Melee, start moving to the other side NOW!", "Threat is reset! Tanks, pick up your new targets quickly!" } },
    ["Ouro"] = { ["Phrases"] = { "Tank swap on Sand Blast! Second tank, get ready!", "HE'S BURROWING! Spread out and dodge the Quake!", "SCARABS ARE UP! Group them up and AOE them down!", "ENRAGE at 20%! He's faster and stronger! Stay focused and burn!" } },
    ["C'Thun"] = { ["Phrases"] = { "PULLING! Get to your assigned group positions NOW!", "SPREAD OUT! Do NOT chain the Eye Beam!", "DARK GLARE! He's turning! Rotate with the beam! Stay alive!", "Claw Tentacles are up! Tanks, grab them! DPS, burn them!", "Eaten players, you are in the stomach! Kill the tentacles inside to weaken the boss!", "VULNERABLE! The eye is weak! All DPS, use cooldowns and BURN HIM NOW!" } }
  },
  ["Zul'Gurub"] = {
    ["High Priestess Jeklik"] = { ["Phrases"] = { "Interrupt her heal! Ranged, stay back to avoid silence!", "BATS INCOMING! AOE them down! Designated ranged, bait the charge!" } },
    ["High Priest Venoxis"] = { ["Phrases"] = { "Melee, stay max range! Do not chain the lightning!", "SNAKE FORM! He's dropping poison clouds! Tank, start kiting him around the room!" } },
    ["High Priestess Mar'li"] = { ["Phrases"] = { "SPIDER ADDS are top priority! Kill them FAST!", "SPIDER FORM! Melee are rooted! Off-tank, grab her when she charges ranged!" } },
    ["Bloodlord Mandokir"] = { ["Phrases"] = { "WATCHING YOU! If he's gazing at you, DO NOT MOVE OR ACT!", "CHARGE! He wiped aggro! Off-tank, taunt him NOW!", "Do not die! Every death makes him stronger!" } },
    ["Edge of Madness Bosses"] = { ["Phrases"] = { "OHGAN: Spread out! Avoid lightning clouds!", "HAZZA'RAH: Mana users, drain his mana! Kill the illusions fast!", "RENATAKI: Vanished! Use AOE to break his stealth!" } },
    ["High Priest Thekal"] = { ["Phrases"] = { "PHASE 1: Kill tiger adds first! Tanks, keep the bosses separated!", "Get all three bosses to 10%... NOW! Group them up and AOE them down!", "PHASE 2: TIGER FORM! Tank swap on Force Punch!" } },
    ["Gahz'ranka"] = { ["Phrases"] = { "Everyone in the water!", "Tank him underwater to nullify his main mechanic. Easy kill!" } },
    ["High Priestess Arlokk"] = { ["Phrases"] = { "Two tanks needed for gouge swaps.", "Marked player, kite the panthers away!", "SHE VANISHED! All DPS, kill the panther adds NOW!", "Backs to the wall! She's about to reappear and burst someone down!" } },
    ["Jindo the Hexer"] = { ["Phrases"] = { "TOTEMS are top priority! Kill Brainwash and Healing Totems first!", "Player teleported to the pit! Get out ASAP!", "Druid tank is best here! Warriors, prepare for hex swaps.", "CURSED PLAYERS! You can see the ghosts! Kill the Shades of Jindo! DO NOT DECURE!" } },
    ["Hakkar the Soulflayer"] = { ["Phrases"] = { "BLOOD SIPHON SOON! Designated puller, bring in a Son of Hakkar!", "Kill the add NOW! Everyone stack in the poison cloud!", "Corrupted Blood is out! If you have it, move away from the raid!", "ENRAGE at 5%! Push him now! Victory is close!" } }
  }
}
