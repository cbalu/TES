# TES - Trip Expense Splitter

## Introduction
TES is a utility developed to calculate individual share for any trip expense, provided every expense incured in the trip can be equally shared among **two or more** persons.
*NOTE: For now I have set the maximum limit the script can handle is 10 persons (You can increase the count and I guess it should work)*

---

## Why BASH ?

* I am well aware that BASH is not the fitting candidate to do this. But I want to have fun with *dialog* and *bc* utility so I chose to implement it with BASH
* Also I can learn BASH scripting along with **git**

---

## Requirements

* Linux machine with bash schell (Ubuntu preferred)
* User with basic understanding of linux shell

---

## How to use TES

### Getting the script for work
If you have git installed in your linux machine you can clone the entire repository using the following command
`git checkout https://github.com/cbalu/TES`

              (or)

If you wish to get only the script file for your usage then do the following
Open [tes.sh](https://raw.githubusercontent.com/cbalu/TES/master/tes.sh) in a new tab in your browser and save the script locally.

### Preparing the script for execution
The script has to be made as executable before running it. This can be achived by changing to the corresponding directory where the script file was saved and then using the following command
`chmod +x tes.sh`
