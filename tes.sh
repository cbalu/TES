#!/bin/bash
#
# TES - Trip Expense Splitter
#
# Date Started: 05/06/2014 (DD/MM/YYYY)
#
# Tested in Ubuntu 12.04 LTS
#
# Revision Log
# ============
# Version 0.1 <===> Pre-alpha release
#

# Global variable
g_var_count=0
g_var_persons=()
g_var_expense=0
g_var_payee=""
g_var_share=()

# Table used to do all calculation on expense
declare -A g_var_table

# Array used to hold author name in hex (name in ascii code)
g_var_authname=("42" "61" "6C" "61" "73" "75" "62" "72" "61" "6D" "61" "6E" "69" "61" "6E" "2E" "43")

# Modify the following value to support higher limit of users
g_var_maxcount=10
# Modify this to suite your currency ( I have used INDIAN RUPEE )
g_var_currency="Rs."

# Return code used to indicate the action status
ret_success=0
ret_err_invalid_number=111
ret_err_max_exceeded=112
ret_err_invalid_input=113
ret_err_invalid_expense=114

# Generic text to be used (Need to find a way for i18n)
#
# msg_general_*  => General banner/UI related messages
# msg_info_*     => Informational message to be used to convey something to user
# msg_err_*      => Error message used to indicate the error
# msg_label_*    => Text used as labels in various UI components
#
msg_general_title="TES"
msg_general_scale="scale=2"  # Scale for BC command (No. of digits after decimal point)
msg_err_invalid_number="Entered value makes no sense, please enter value in range 2 to $g_var_maxcount"
msg_err_max_exceeded="Entered value is more than what we can handle now, please enter value in range 2 to $g_var_maxcount"
msg_err_invalid_input="Entered value doesn't seems to be a valid integer, please enter value in range 2 to $g_var_maxcount"
msg_err_empty_name="One/many of the name is empty, fill all person(s) name to proceed"
msg_err_invalid_expense="Invalid input, enter valid expense amount"
msg_err_min_share_count="Please pick atleast two persons who share the expense"
msg_err_need_payee="Please pick the person who did the payment to proceed further"
msg_err_pick_indiv="Please choose a person to know his share"
msg_info_add_success="Details added successfully"
msg_info_empty_log="No details have been added, nothing to show now"
msg_info_confirm_exit="Do you want to quit the app ?"
msg_info_onexit="Bye, have a nice day :)\nPress ENTER/ESC key to quit"
msg_label_back="Back"

# Used for debugging purpose
function _debug {
	if [[ $2 -eq 0 ]]; then
		echo $1 >> debug.txt
	else
		echo $1 > debug.txt
	fi
}

# Write the log to file
function _write_log {
	local var_echo=""
	if [[ $2 -eq 0 ]]; then
		var_echo="echo"
	else
		var_echo="echo -n"
	fi

	if [ -f log.txt ]; then
		$var_echo $1 >> log.txt
	else
		$var_echo $1 > log.txt
	fi
}

# General call to show informational message
function _show_message {
	dialog --stdout --backtitle "$msg_general_title" --title "****** MESSAGE ******" --msgbox "$1" 10 70
}

# General call to show any error message
function _show_error {
	dialog --stdout --backtitle "$msg_general_title" --colors --title "****** ERROR ******" --msgbox "\Zb\Z1$1\ZB\Zn\n" 10 70
}

# Show exit/quit confirmation message
function _show_exit_message {
	dialog --stdout --backtitle "$msg_general_title" --yesno "$msg_info_confirm_exit" 8 40
	case "$?" in
	0)		_show_message "$msg_info_onexit"
			rm -f log.txt > /dev/null 2>&1
			rm -f calc.txt > /dev/null 2>&1
			clear
			exit
			;;
	1)		$1
			;;
	255)	$1
			;;
	esac
}

# General call to handle both <Back> button and ESC key press
function validate_keystroke {
	case "$?" in
	1)		$2
			;;
	255)	_show_exit_message $1
			;;
	esac
}

# Validate the person count read from user
function validate_count {
	if [[ $1 != *[!0-9]* ]]; then
		if [[ $1 -eq 0 ]] || [[ $1 -eq 1 ]]; then
			echo $ret_err_invalid_number                # We got value which makes no sense
		elif [[ $1 -le $g_var_maxcount ]]; then
			echo $ret_success                           # We got a valid value so we can proceed further
		else
			echo $ret_err_max_exceeded                  # We got value which we can't handle now
		fi
	else
		echo $ret_err_invalid_input                     # We haven't got a valid number
	fi
}

# Validate the expense input read from user
function validate_expense {
	if [[ $1 != *[!0-9]* ]]; then
		if [[ $1 -le 0 ]]; then
			echo $ret_err_invalid_expense               # We got expense which makes no sense
		else
			echo $ret_success                           # We got a valid value so we can proceed further
		fi
	else
		echo $ret_err_invalid_expense                   # We got expense which makes no sense
	fi
}

# Clear global variable which are going to be reused
function clear_global_vars {
	g_var_expense=0
	g_var_payee=""
	g_var_share=""
}

# Initialize the table before any calculation
function do_table_init {
	local var_i=0
	local var_j=0

	for ((var_i=0;var_i<$g_var_maxcount;var_i++)) do
		for ((var_j=0;var_j<$g_var_maxcount;var_j++)) do
			g_var_table[$var_i,$var_j]=0
		done
	done
}

# Do the calculation for equally splitting the expense
function do_eqsplit_calculations {
	local var_individual_share=0
	local var_share_count=${#g_var_share[@]}
	local var_payee_index=$(( $g_var_payee-1 ))
	local var_i=0
	local var_j=0
	local var_k=0

	# Get individual share as we are equally splitting
	var_individual_share=$(echo "$msg_general_scale; $g_var_expense / $var_share_count" | bc)

	# Logic for calculating individual share
	for ((var_i=0;var_i<$g_var_count;var_i++)) do
		for ((var_j=0;var_j<$g_var_count;var_j++)) do
			if [[ $var_i -eq $var_payee_index ]]; then
				for ((var_k=0;var_k<$var_share_count;var_k++)) do
					if [[ $var_j -eq $(( ${g_var_share[$var_k]}-1 )) && $var_i -ne $var_j ]]; then
						g_var_table[$var_i,$var_j]=$(echo "$msg_general_scale; ${g_var_table[$var_i,$var_j]} + $var_individual_share" | bc)
						break
					fi
				done
			else
				break
			fi
		done
	done

	# TIP: This code was commented using regex in vim, under command mode
	# Shift + V - Select the section
	# Type :s/^/# - To comment the block selected
	# Type :s/^#// - To uncomment the block selected
#	_debug "Printing the table values as follows" 0
#	for ((var_i=0;var_i<$g_var_count;var_i++)) do
#		for ((var_j=0;var_j<$g_var_count;var_j++)) do
#			_debug "Table [ $var_i, $var_j ] = ${g_var_table[$var_i,$var_j]}" 0
#		done
#	done
}

# Read who are sharing the particular expense incured
function pick_persons {
	local var_i=1
	local var_share_len=0
	local var_cmd="dialog --stdout --separate-output --cancel-label \"$msg_label_back\" --backtitle \"$msg_general_title\" --title \"****** PICK PERSONS ******\" --checklist \"Select the person(s) who share $g_var_currency$g_var_expense paid by ${g_var_persons[$(( $g_var_payee-1 ))]}\" 20 60 5"
	while [[ var_i -le $g_var_count ]]
	do
		var_cmd="$var_cmd \"$var_i\" \"${g_var_persons[$(( $var_i-1 ))]}\""
		# Make sure payee got selected by default for share
		if [[ $var_i -eq $g_var_payee ]]; then
			var_cmd="$var_cmd ON"
		else
			var_cmd="$var_cmd OFF"
		fi
		(( var_i++ ))
	done
	g_var_share=(`eval $var_cmd`)
	validate_keystroke $FUNCNAME pick_payee

	# Make sure we have atleast two persons to share the expense
	var_share_len=${#g_var_share[@]}
	if [[ $var_share_len -eq 0 || $var_share_len -eq 1 ]]; then
		_show_error "$msg_err_min_share_count"
		$FUNCNAME
	else
		do_eqsplit_calculations
		_write_log "$g_var_currency$g_var_expense paid by \"${g_var_persons[$(( $g_var_payee-1 ))]}\" is shared among \"" 1
		for ((var_i=0;var_i<${#g_var_share[@]};var_i++)) do
			if [[ $var_i -ne 0 ]]; then
				_write_log ", " 1
			fi
#			if [[ $var_i -eq $(( ${g_var_share[$var_i]}-1 )) ]]; then
#				_write_log "${g_var_persons[$var_i]}" 1
#			fi
			_write_log "${g_var_persons[$(( ${g_var_share[$var_i]}-1 ))]}" 1
		done
		_write_log "\"" 0
		_show_message "$msg_info_add_success"
		clear_global_vars
		draw_menu
	fi
}

# Read who made the payment for the particular transaction
function pick_payee {
	local var_i=1
	local var_cmd="dialog --stdout --cancel-label \"$msg_label_back\" --backtitle \"$msg_general_title\" --title \"****** PICK PAYEE ******\" --radiolist \"Who paid $g_var_currency$g_var_expense for the expense\" 20 60 5"
	while [[ var_i -le $g_var_count ]]
	do
		var_cmd="$var_cmd \"$var_i\" \"${g_var_persons[$(( $var_i-1 ))]}\" OFF"
		(( var_i++ ))
	done
	g_var_payee=(`eval $var_cmd`)
	validate_keystroke $FUNCNAME get_total_expense

	if [[ ${#g_var_payee} -eq 0 ]]; then
		_show_error "$msg_err_need_payee"
		$FUNCNAME
	else
		pick_persons
	fi
}

# Read total expense incured for a particular cause
function get_total_expense {
	g_var_expense=`dialog --stdout --cancel-label "$msg_label_back" --backtitle "$msg_general_title" --title "****** EXPENSE AMOUNT ******" --inputbox "Enter amount spent: " 0 0`
	validate_keystroke $FUNCNAME draw_menu

	local var_ret=$(validate_expense $g_var_expense)
	if [[ $var_ret -eq $ret_err_invalid_expense ]]; then
		_show_error "$msg_err_invalid_expense"
		$FUNCNAME
	else
		pick_payee
	fi
}

# Show my name
function show_author_name {
	local var_cmd="printf \""
	local var_i=0
	while [[ var_i -le $(( ${#g_var_authname[@]}-1 )) ]]
	do
		var_cmd="$var_cmd\x${g_var_authname[$var_i]}"
		(( var_i++ ))
	done
	var_cmd="$var_cmd\""
	local var_name=(`eval $var_cmd`)
	dialog --stdout --backtitle "$msg_general_title" --title "****** AUTHOR NAME ******" --msgbox "Author Name: $var_name" 10 50
	draw_menu
}

# Show recorded log for all details entered
function show_detail_log {
	# Read the log file and show the content
	if [ -f log.txt ]; then
		dialog --stdout --exit-label "$msg_label_back" --backtitle "$msg_general_title" --title "****** LOG ******" --textbox log.txt 30 60
	else
		_show_message "$msg_info_empty_log"
	fi
	validate_keystroke draw_menu draw_menu
	draw_menu
}

# Compute indiviual share
function show_individual_share {
	local var_i=1
	local var_amt=0
	local var_req=""

	rm -f calc.txt > /dev/null 2>&1
	if [ -f log.txt ]; then
		# Nothing to do here proceed freely
		echo "" > calc.txt
	else
		_show_message "$msg_info_empty_log"
		validate_keystroke draw_menu draw_menu
		draw_menu
	fi
	
	# Pick the person for whom the calculation has to be done
	local var_cmd="dialog --stdout --cancel-label \"$msg_label_back\" --backtitle \"$msg_general_title\" --title \"****** INDIVIDUAL SHARE ******\" --radiolist \"Pick person for whom we need to calculate his share\" 20 60 5"
	while [[ var_i -le $g_var_count ]]
	do
		var_cmd="$var_cmd \"$var_i\" \"${g_var_persons[$(( $var_i-1 ))]}\" OFF"
		(( var_i++ ))
	done
	var_req=(`eval $var_cmd`)
	validate_keystroke $FUNCNAME draw_menu

	# We got the person, do calculation and write it to file
	if [[ $var_req -eq 0 ]]; then
		_show_error "$msg_err_pick_indiv"
		validate_keystroke draw_menu draw_menu
		$FUNCNAME
	else
		for ((var_i=0;var_i<$g_var_count;var_i++)) do
			if [[ $var_i -eq $(( $var_req-1 )) ]]; then
				continue
			else
				if [[ $(echo "$msg_general_scale; ${g_var_table[$(( $var_req-1 )),$var_i]} == ${g_var_table[$var_i,$(( $var_req-1 ))]}" | bc) -eq 1 ]]; then
					echo "\"${g_var_persons[$(( $var_req-1 ))]}\" has to give/get nothing to/from \"${g_var_persons[$var_i]}\"" >> calc.txt
				elif [[ $(echo "$msg_general_scale; ${g_var_table[$(( $var_req-1 )),$var_i]} > ${g_var_table[$var_i,$(( var_req-1 ))]}" | bc) -eq 1 ]]; then
					var_amt=$(echo "$msg_general_scale; ${g_var_table[$(( $var_req-1 )),$var_i]} - ${g_var_table[$var_i,$(( var_req-1 ))]}" | bc)
					echo "\"${g_var_persons[$(( $var_req-1 ))]}\" has to get $g_var_currency$var_amt from \"${g_var_persons[$var_i]}\"" >> calc.txt
				else
					var_amt=$(echo "$msg_general_scale; ${g_var_table[$var_i,$(( $var_req-1 ))]} - ${g_var_table[$(( $var_req-1 )),$var_i]}" | bc)
					echo "\"${g_var_persons[$(( $var_req-1 ))]}\" has to give $g_var_currency$var_amt to \"${g_var_persons[$var_i]}\"" >> calc.txt
				fi
			fi
		done
	fi

	# Read the file and show the content to user
	dialog --stdout --exit-label "$msg_label_back" --backtitle "$msg_general_title" --title "****** SHARE ******" --textbox calc.txt 30 60
	validate_keystroke draw_menu draw_menu
	draw_menu
}

# Show menu for the user to choose between various options
function draw_menu {
	local var_ret=`dialog --stdout --cancel-label "$msg_label_back" --backtitle "$msg_general_title" --title "****** MENU ******" --menu "Please choose one of the following option:" 20 60 5 \
	                      1 "Add trip details (Equal split)" \
	                      2 "Show individual share" \
	                      3 "Show details log" \
	                      4 "Show author name" \
	                      5 "Exit this program"`
	validate_keystroke $FUNCNAME get_person_names
	if [[ $var_ret -eq 1 ]]; then
		get_total_expense
	elif [[ $var_ret -eq 2 ]]; then
		show_individual_share
	elif [[ $var_ret -eq 3 ]]; then
		show_detail_log
	elif [[ $var_ret -eq 4 ]]; then
		show_author_name
	elif [[ $var_ret -eq 5 ]]; then
		_show_exit_message $FUNCNAME
	else
		echo "This case is not possible"
	fi
}

# Get individual person name for proceeding further
function get_person_names {
	local var_i=1
	local var_cmd="dialog --stdout --cancel-label \"$msg_label_back\" --backtitle \"$msg_general_title\" --title \"****** ENTER PERSON DETAILS ******\" --form \"Enter individual name in following field:\" 18 60 0"
	while [[ var_i -le $g_var_count ]]
	do
		var_cmd="$var_cmd \"Person$var_i Name: \" $var_i 1 \"${g_var_persons[$(( $var_i-1 ))]}\" $var_i 20 20 0"
		(( var_i++ ))
	done
	IFS=$'\n'
	g_var_persons=(`eval $var_cmd`)
	validate_keystroke $FUNCNAME get_count
	unset IFS

	local var_k=0
	while [[ var_k -lt $g_var_count ]]
	do
		if [[ ${#g_var_persons[$var_k]} -eq 0 ]];
		then
			_show_error "$msg_err_empty_name"
			$FUNCNAME
		fi
		(( var_k++ ))
	done

	do_table_init
	draw_menu
}

# Read number of persons involved in the trip
function get_count {
	g_var_count=`dialog --stdout --nocancel --backtitle "$msg_general_title" --title "****** PERSON COUNT ******" --inputbox "Enter no. of persons involved in the trip (for now max $g_var_maxcount): " 10 50`
	validate_keystroke $FUNCNAME get_count
	local var_ret=$(validate_count $g_var_count)
	if [[ $var_ret -eq $ret_err_invalid_number ]]; then
		_show_error "$msg_err_invalid_number"
		$FUNCNAME
	elif [[ $var_ret -eq $ret_err_max_exceeded ]]; then
		_show_error "$msg_err_max_exceeded"
		$FUNCNAME
	elif [[ $var_ret -eq $ret_err_invalid_input ]]; then
		_show_error "$msg_err_invalid_input"
		$FUNCNAME
	else
		get_person_names
	fi
}

# Welcome message
function welcome_message {
	# I agree its not a very worm welcome, but still we start with greetings
	dialog --colors --no-collapse --backtitle "$msg_general_title" --msgbox "       Welcome to \ZuTES\ZU\n( \ZbT\ZBrip \ZbE\ZBxpense \ZbS\ZBplitter )" 0 0
	get_count
}

# Make sure we have the tools to finish the job at hand
function check_prerequisite {
	local var_fail=0
	local var_tput_found=0
	local var_dialog_notfound=0
	local var_bc_notfound=0

	# If 'tput' is available then we can make use of it to show
	# colorful information to user to make it readable
	tput -V > /dev/null 2>&1
	if [[ $? -eq 0 ]]; then
		var_tput_found=1
	fi
	echo "=========================================================="
	echo "#### INITIATING PREREQUISITE CHECK TO RUN APPLICATION ####"
	echo "=========================================================="
	if [[ $var_tput_found -eq 1 ]]; then
		echo "$(tput bold)$(tput setaf 7)"
	fi

	# We need 'dialog' this entire script make use of that to show
	# various components. So check is mandatory for the utility
	dialog -v > /dev/null 2>&1
	if [[ $? -eq 0 ]]; then
		if [[ $var_tput_found -eq 1 ]]; then
			echo "$(tput setaf 2)"
		fi
		echo "Checking for the presence of dialog utility .... [   FOUND   ]"
		if [[ $var_tput_found -eq 1 ]]; then
			echo "$(tput setaf 7)"
		fi
	else
		if [[ $var_tput_found -eq 1 ]]; then
			echo "$(tput setaf 1)"
		fi
		echo "Checking for the presence of dialog utility .... [ NOT FOUND ]"
		var_dialog_notfound=1
		var_fail=1
		if [[ $var_tput_found -eq 1 ]]; then
			echo "$(tput setaf 7)"
		fi
	fi

	# We need 'bc' as by default bash shell doesn't support floating
	# arithmetic operation and we require those functionality in this
	# script to make the calculation meaningfull
	bc -v > /dev/null 2>&1
	if [[ $? -eq 0 ]]; then
		if [[ $var_tput_found -eq 1 ]]; then
			echo "$(tput setaf 2)"
		fi
		echo "Checking for the presence of bc utility .... [   FOUND   ]"
		if [[ $var_tput_found -eq 1 ]]; then
			echo "$(tput setaf 7)"
		fi
	else
		if [[ $var_tput_found -eq 1 ]]; then
			echo "$(tput setaf 1)"
		fi
		echo "Checking for the presence of bc utility .... [ NOT FOUND ]"
		var_bc_notfound=1
		var_fail=1
		if [[ $var_tput_found -eq 1 ]]; then
			echo "$(tput setaf 7)"
		fi
	fi
	if [[ $var_tput_found -eq 1 ]]; then
		echo "$(tput sgr0)"
	fi

	# If we find any missing utility then report to user along
	# with how to install the required tools, if things are
	# well here then lets start rolling by showing welcome
	if [[ $var_fail -eq 1 ]]; then
		echo "Please install missing component by running the following command from your terminal"
		echo ""
		echo -n "\" sudo apt-get install"
		if [[ $var_dialog_notfound -eq 1 ]]; then
			echo -n " dialog "
		elif [[ $var_bc_notfound -eq 1 ]]; then
			echo -n " bc "
		else
			echo -n " "
		fi
		echo "\""
		echo ""
		echo "After installing missing component(s) re-run this application"
		echo "==========================================================="
		echo "#### PREREQUISITE CHECK FAILED SO QUITTING APPLICATION ####"
		echo "==========================================================="
		exit
	else
		welcome_message
	fi
}

# Everything needs a starting point and here is ours
check_prerequisite
