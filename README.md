# ✨ASM-Chat✨
A chat protocol written entirely in 64 bit ASM, with 0 dependancies
## Running the program
To run this code on your computer, there are 3 options:
- Assemble and link the [source code](main.asm)
- Link the pre assembled [.out file](main.out)
- Download and run the [executable](main)
#### Assembling and linking from source
The source code is written entirely in 64 bit assembly and will need to first be compiled with **NASM** using the command\
```nasm -o main.out -f elf64 main.asm```\
This will generate an assembled file which will also then need to be linked in order to generate an executable. Linking can be done with any linker but this example will use ld\
```ld -o main main.out```\
The resulting file will be executable by default so there is no need to chmod the file. **For the .out file, you will only need to link the .out file and the executable can just be executed without anything else required**
##### NOTE: You will only need to use the source code if you want to modify this code or the pre-assembled files provided in this repo do not work

## Selection windows
Upon starting the program, you should see a screen which shows a small window in the center of the screen, in which you are given a choice for your program to function as a server, or a client.\
Pressing the letter ```C``` will send you to the client menu, and pressing ```S``` will send you to the server menu. Pressing ESC at any point will take you to the previous page, or kill the program if you are at the home screen.
### Client and server menus
In the client menu, there program will first ask you for the IP address of the server that you wish to connect to. there are a variety of ways you can do this on linux, but most of the time you can view your local IP from the output of the command ```ifconfig```. If this command is not found, it can be installed with a package that is known as net-tools on most linux systems. If you enter an IP address above or at the input limit, the program will automatically forward you to name selection.
##### NOTE: The IP address entered MUST be in ipv4 format otherwise the code will redirect you to the home screen
After entering an IP address from the client menu or after pressing ```S``` to go to the server menu, the program will them ask for you to input your name. This of course does not need to be your actual name, and this is just the name that the program will display next to your messages. As with the IP input, going over the character limit will automatically forward you to the next section\
After all this has been filled out, the program will then either connect to the server if you chose to act as a client, or will start a server and listen for connections if you chose to act as a server.
#### As a server
When you start a server, the program will stop and wait for incomming connections. During this period, the program will not be doing anything, so dont worry if nothing is happening. Once the server recieves a connection, the server window will immediately close and you will be able to send messages between each other.
#### As a client
When you attempt to connect to a server, a number of things can happen. If you entered the IP correctly and the server is running properly, you will immediately be forwarded to being able to talk between you and the server. However, if you entered the incorrect IP, the client will either stall if the IP does not exist, or redirect you to the start page if the IP address you entered existed, but was not hosting a server. If your program stalls, it is safe to Ctrl+C the program and start again with correct IP values.
## Chat menu
After connecting to your peer, the window in the middle will dissapear and you will be able to send messages inbetween you and the peer. Currently, all languages are supported **apart from languages like chinese which use alternate input methods**, as they mess up the way that characters are recorded. The characters should render properly, but features which rely on the length of the text input being correct (line wrapping), will usually not work properly.
#### Disconnecting
To disconnect from your peer, **DO NOT USE CTRL+C** but instead type ```!d``` into the message box and press enter. Alternatively, ```!q``` can be used to disconnect and then close the program. Using Ctrl+C to disconnect will cause the peer's program to segfault, and sometimes this can result in orphaned processes being left on the system. Hence, if your program returns to the menu screen half way through talking, it means your peer has disconnected.
## FAQ
### Should I choose client or server?
When you choose server, the program will wait for someone else to connect to your computer. This means that if you wish to connect to someone elses computer, you should choose client and then input the other persons computer IP. However that other computer needs to already be hosting a server for you to be able to connect. In short, the first person to start the program should be the server, and the second should be client.
### Can I use this program with computers on different WiFi networks?
This program works usually using local IP addresses, which means that you can easily communicate between computers on the same WiFi network using their local IPs. The program *does* work accross computers on different WiFi networks, but requires that you first set up port forwarding on your router which redirects traffic on port 9001 to your computer. Then when the client connects, they will instead need to use the servers **global IP** instead of their local IP. (Your global IP can be found [here](https://whatismyipaddress.com/))
# Thank you! 💖
