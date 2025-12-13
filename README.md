# ECE-287-Crossy-Road-Final-Project
Breakdown on a Crossy Road Final Project ECE 287: Digital Systems Design 
Within the README section you will be able to look through a rundown or each module (which can also be found in the src folder). 



                                               What Is Frogger? 

Frogger is a classic arcade game where the player controls a frog trying to cross across 'dangerous' lanes of traffic to reach safe 'home' slots at the top of the screen. Some of the main core gamplay concepts are as follows: 

1. Grid Based Movement
     Frogger moves one tile at a time (up, down, left, right). 
2. Player Objective
     Frogger starts at the bottom of the screen and makes it way back to the very top (where y = 0). Frogger must avoid any obstacles in its path as it journeys upward. 
3. Hazards / Obstacles
      If Frogger hits a vehicle, it will lose. Along with many other applications that will also make it lose. 
4. Score System
      Having Frogger move forward make it gain points; reaching a home slot gives it a bonus and/or bring a fly gives extra points as well. 
5. End Conditions
      The level ends once Frogger has made it to the top of the screen safetly or when it has lost all its lives.



                          Frogger Application in FPGA DE1-SoC Board: Crossy Road 

For our final project, we have impleemnted a version of Frogger in the form of Crossy Road. This was done by considering a couple of things, specifically, the Finite State Machine used for this project. 

...


Here is our FSM diagram of our simple FSM states in the game:

![IMG_0096](https://github.com/user-attachments/assets/c24566a9-0672-45b6-94a8-e3f80fc35201)
                               Figure 1. FSM Diagram















                      Display Logic & Instantiating a ROM IP Core via IP Catalog 

When dealing with the Display Logic, there were two different ways this was addressed by our team:

Once the full logic was implemented throughout the project, the game display looked like Figure 2, a simply solid color for where said sprite or object logic was happening. 



