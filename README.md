# TES - Trip Expense Splitter

## Introduction
TES is a utility developed to calculate individual share for any trip expense, provided every expense incured in the trip can be equally shared among **two or more** persons. Beware although intermidiate files are used during computation the values entered will be available in memory only so once you close the application your details will be lost.

*NOTE: For now I have set the maximum limit the script can handle is 10 persons (You can increase the count and I guess it should work)*


## Why BASH ?

* I am well aware that BASH is not the fitting candidate to do this. But I want to have fun with *dialog* and *bc* utility so I chose to implement it with BASH
* Also I can learn BASH scripting along with **git**


## Requirements

* Linux machine with bash schell (Ubuntu preferred)
* User with basic understanding of linux shell


## How to use TES

### Keybindings

* Use `<ENTER>` key to always proceed to next step
* Use `<SPACEBAR>` key to make the selection
* Use `<UP> <DOWN>` arrow keys to navigate between textbox and choice selections
* Use `<TAB>` key to change to **OK** and **BACK** buttons
* Use `<ESC>` key anytime to quit/exit from the script

### Getting the script for work
If you have git installed in your linux machine you can clone the entire repository using the following command

`git checkout https://github.com/cbalu/TES`


              (or)


If you wish to get only the script file for your usage then do the following

Open [tes.sh](https://raw.githubusercontent.com/cbalu/TES/master/tes.sh) in a new tab in your browser and save the script locally.

### Preparing the script for execution
The script has to be made as executable before running it. This can be achived by changing to the corresponding directory where the script file was saved and then using the following command

`chmod +x tes.sh`

### Executing the script
The script can be executed by cahnging to the corresponding directory where the script file is saved and then invoked by the following command

`./tes.sh`

Once the script starts execution the first thing it does is by checking the tools required to make it run and if it can't find them then it shows the corresponding error along with instruction to install the missing tools. The following image shows one such case

![alt text](https://raw.githubusercontent.com/cbalu/TES/master/screenshots/00-dependency_error.png "Sample error message")

Install the missing tools and then re-run the script.

## Steps to add details

### Welcome screen
If all the dependant tools are present in the machine then the script will start its execution with the welcome message. 

Sample Screenshot: [welcome message](https://raw.githubusercontent.com/cbalu/TES/master/screenshots/01-welcome_screen.png)

### Enter persons count
Once you get past the welcome message you can enter how many persons involved in the trip. For now we accept **minimum 2 persons and maximum 10 persons**
Sample Screenshot: [person count](https://raw.githubusercontent.com/cbalu/TES/master/screenshots/02-no_of_persons.png)

### Enter persons name
Based on the count the script shows the corresponding text field to enter persons name involved in trip. You can use `<UP> <DOWN>` arrows to navigated between different name text field. Once the names are entered you can use `<ENTER>` key to proceed further.
Sample Screenshot: [person name](https://raw.githubusercontent.com/cbalu/TES/master/screenshots/03-person_names.png)

### Menu selection
You can use `<UP> <DOWN>` or numbers to select the corresponding items in menu then use `<ENTER>` key to make the selection.
Sample Screenshot: [menu](https://raw.githubusercontent.com/cbalu/TES/master/screenshots/04-menu.png)

### Adding trip expense
Once you choose the **Add trip details (Equal split)**  in menu, you can start entering the expense incurred for individual item and then who paid the expense(use `<SPACEBAR>` to make the selection) along with who are all the persons going to share the expense. Once the details has been added a confirmation message is shown
Sample Screenshots: [expense-cost](https://raw.githubusercontent.com/cbalu/TES/master/screenshots/05-enter_expense.png) - [pick-payee](https://raw.githubusercontent.com/cbalu/TES/master/screenshots/06-pick_payee.png) - [persons-sharing](https://raw.githubusercontent.com/cbalu/TES/master/screenshots/07-share_persons.png) - [confirmation-msg](https://raw.githubusercontent.com/cbalu/TES/master/screenshots/08-details_added.png)

### Viewing log
You can view the log for every expense added from the menu by selecting **Show details log**
Sample Screenshots: [menu](https://raw.githubusercontent.com/cbalu/TES/master/screenshots/09-view_log.png) - [log-view](https://raw.githubusercontent.com/cbalu/TES/master/screenshots/10-log_view.png)

### Getting individual share
You can get individual person share by selecting **Show individual share** under menu and then selecting the corresponding persons (use `<SPACEBAR>` to make the selection) for whom we need to calculate his share
Sample Screenshots: [menu](https://raw.githubusercontent.com/cbalu/TES/master/screenshots/11-individual_share.png) - [pick-person](https://raw.githubusercontent.com/cbalu/TES/master/screenshots/12-pick_person_for_share.png) - [view-share](https://raw.githubusercontent.com/cbalu/TES/master/screenshots/13-share_view.png)

### Exiting the application
You can exit the application using two ways. You can always use the `<ESC>` key anytime to bring up the exit confirmation message and also choose the **Exit this program** option under menu. Once you confirm the exit the script will stop execution, this is the proper way to end the application **DONOT USE CTRL+C COMBINATION TO END THE APPLICATION**
Sample Screenshots: [menu](https://raw.githubusercontent.com/cbalu/TES/master/screenshots/14-exit_option.png) - [exit-confirmation](https://raw.githubusercontent.com/cbalu/TES/master/screenshots/15-exit_confirmation.png) - [goodbye](https://raw.githubusercontent.com/cbalu/TES/master/screenshots/16-final_goodbye.png)

## Revision Log

* 0.1 - Pre-alpha release with equal split options and ability to compute individual share

## License

You are free to use the code for both personal and commercial purpose as the license it accompains is GPL v3. For further details please refer the [link](http://www.gnu.org/copyleft/gpl.html)
