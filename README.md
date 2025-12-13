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

Once the full logic was implemented throughout the project, the game display looked like Figure 2, a simple solid color for where said sprite or object logic was happening. This is the easiest way to visualize the game logic that is being implemented without adding additional levels of unnecessary concern in the moment. 

![Image](https://github.com/user-attachments/assets/f4f21ea7-7768-421a-adef-542a9b908b41)

Figure 2. Full Logic Imeplementation with Grid Blocks 
                  

However, once you are at a good point in your project where all you have left to worry about is the display images themselves, you can address game display with Intel FPGA IP Cores, the one we did in this project. All Display logic happens in the vga_driver_memory.v file within this project, resulting in the final game image (Figure 3). 

![Image](https://github.com/user-attachments/assets/1e45e480-1f60-450e-9868-6f53b47a840f)
Figure 3. Full Game Display w/ Images 

STEPS TO FOLLOW: as an example guide on how to do this method, the following will be a step-by-step breakdown on how to display image for sprite2 within crossy_road project. 
1. Choose an Image to represent [sprite2] with online search. 
2. Save as a .png image.
3. Go to Claude by Anthropic and upload prompt "create a png to mif converter to upload mif files to quartus". (see Figure 4)
<img width="2313" height="1073" alt="Image" src="https://github.com/user-attachments/assets/e249ac26-9167-4b38-b2b5-86f7579f3f65" /> 
Figure 4. Prompting Claude by Anthropic to create a mif converter                 
4. 




