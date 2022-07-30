#!/bin/bash
#
# TES - Trip Expense Splitter
# Copyright (C) 2022  BalaC
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Date Started: 05/06/2014 (DD/MM/YYYY)
#
# Tested in Ubuntu 12.04 LTS
#
# Revision Log
# ============
# Version 0.2 <===> Fixed minor issue and introduced calendar
#
# Version 0.1 <===> Pre-alpha release
#

# Global variable
g_var_count=0
g_var_persons=()
g_var_date=""
g_var_desc=""
g_var_expense=0
g_var_share=()
g_var_payees_amt=()
g_var_payees_index=()

# Global variable used to hold random number
g_var_rndnum=$RANDOM
g_var_autoclose_sec=3

# Table used to do all calculation on expense
declare -A g_var_table

# Array used to hold author name in hex (name in ascii code)
g_var_authname=("42" "61" "6C" "61" "73" "75" "62" "72" "61" "6D" "61" "6E" "69" "61" "6E" "2E" "43")

# Modify the following value to support higher limit of users
g_var_maxcount=10

# Modify this to suite your currency ( I have used INDIAN RUPEE )
g_var_currency_prefix="Rs. "
g_var_currency_suffix=""

# Return code used to indicate the action status
ret_success=0
ret_err_invalid_input=111
ret_err_invalid_expense=112
#ret_err_invalid_number=113
#ret_err_max_exceeded=114

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
msg_err_invalid_input="Entered value doesn't seems to be a valid one, please enter value in range 2 to $g_var_maxcount"
msg_err_empty_name="One/many of the name is empty, fill all person(s) name to proceed"
msg_err_invalid_expense="One/many of expense is invalid, enter valid expense amount"
msg_err_missing_description="Short description is missing, please fill that field"
msg_err_missing_expense="Amount spent value is missing, please fill that field"
msg_err_min_share_count="Please pick atleast two persons who share the expense"
msg_err_need_payee="Please pick the person(s) who did the payment to proceed further"
msg_err_pick_indiv="Please choose a person to know his/her share"
msg_info_add_success="Details added successfully"
msg_info_empty_log="No details have been added, nothing to show now"
msg_info_confirm_exit="Do you want to quit the app ?"
msg_info_onexit="Bye, have a nice day :)\nPress ENTER/ESC key to quit"
msg_label_back="Back"
msg_label_pickdate="Pick date"

# General options to be used
option_debug_append_text=0
option_debug_overwrite_text=1
option_log_add_newline=0
option_log_no_newline=1

# Used for debugging purpose
function _debug {
	if [[ $2 -eq $option_debug_append_text ]]; then
		echo $1 >> debug.txt
	else
		echo $1 > debug.txt
	fi
}

# Write the log to file
function _write_log {
	local var_echo=""
	if [[ $2 -eq $option_log_add_newline ]]; then
		var_echo="echo"
	else
		var_echo="echo -n"
	fi

	if [ -f .$g_var_rndnum.log ]; then
		$var_echo $1 >> .$g_var_rndnum.log
	else
		$var_echo $1 > .$g_var_rndnum.log
	fi
}

# General call to show informational message which gets closed after specified seconds
# If seconds parameter is not provided then default 'g_var_autoclose_sec' seconds will be used
function _show_auto_close_message {
	if [ -z "$2" ]; then
		dialog --stdout --backtitle "$msg_general_title" --title "****** MESSAGE ******" --pause "$1" 10 70 $g_var_autoclose_sec
	else
		dialog --stdout --backtitle "$msg_general_title" --title "****** MESSAGE ******" --pause "$1" 10 70 $2
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

# Remove the intermitant files
function perform_cleanup {
	rm -f .$g_var_rndnum.log > /dev/null 2>&1
	rm -f .$g_var_rndnum.calc > /dev/null 2>&1
	rm -f .tmp > /dev/null 2>&1
}

# Show exit/quit confirmation message
function _show_exit_message {
	dialog --stdout --backtitle "$msg_general_title" --yesno "$msg_info_confirm_exit" 8 40
	case "$?" in
	0)		_show_auto_close_message "$msg_info_onexit" 5
			perform_cleanup
			clear
			exit
			;;
	1)		$1
			;;
	255)	$1
			;;
	esac
}

# General call to handle both <Back> button and <ESC> key press
function validate_keystroke {
	case "$1" in
	1)		$3
			;;
	255)	_show_exit_message $2
			;;
	esac
}

# Validate the input number read from user
# used to validate person(s) count
function validate_count {
	local input_number=$1

	# Check for whole number
	if [[ $input_number =~ ^[0-9]+$ ]]; then
		echo $ret_success
		return
	fi

	# We haven't got a valid number
	echo $ret_err_invalid_input
}

# Validate the input number for floating point with scale of 2 atmost
# also whole number is accepted, used to validate amount/expense
function validate_expense {
	local input_number=$1

	# Check for floating point number/whole number
	if [[ $input_number =~ ^[0-9]+(\.?[0-9]{1,2})$ ]]; then
		echo $ret_success
		return
	fi

	# We haven't got a valid number
	echo $ret_err_invalid_expense
}

# Clear global variable which are going to be reused
function clear_global_vars {
	g_var_expense=0
	g_var_desc=""
	g_var_share=()
	g_var_payees_amt=()
	g_var_payees_index=()
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
function do_share_calculation {
	local var_individual_share=0
	local var_share_count=${#g_var_share[@]}
	local var_payee_index=0
	local var_i=0
	local var_j=0
	local var_k=0
	local var_x=0
	local var_temp=()
	local var_ps_count=0
	local var_ng_count=0
	local var_index=0

	var_individual_share=$(echo "$msg_general_scale; $g_var_expense / $var_share_count" | bc)

	# Check whether the amount is paid by single person/multiple persons
	if [[ ${#g_var_payees_index[@]} -eq 1 ]]; then
		# Payment done by single person, get individual share as we are equally splitting
		var_payee_index=$(( ${g_var_payees_index[0]}-1 )) #Only one payee is available so always read 0th index

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
	else
		# Payment done by multiple persons
		for ((var_i=0;var_i<$g_var_count;var_i++)) do
			var_temp[$var_i]=0
		done

		for ((var_i=0;var_i<$var_share_count;var_i++)) do
			var_index=${g_var_share[$var_i]}
			for ((var_j=0;var_j<${#g_var_payees_index[@]};var_j++)) do
				if [[ $var_index -eq ${g_var_payees_index[$var_j]} ]]; then
					var_temp[$(( $var_index-1 ))]=$(echo "$msg_general_scale; $var_individual_share - ${g_var_payees_amt[$var_j]}" | bc)
					if [[ $(echo "$msg_general_scale; ${var_temp[$(( $var_index-1 ))]} > 0" | bc) -eq 1 ]]; then
						_debug "Got an positive value, so increment count" $option_debug_append_text
						(( var_ps_count++ ))
					else
						_debug "Got an negative value, so increment count" $option_debug_append_text
						(( var_ng_count++ ))
					fi
				fi
			done
		done
		_debug "Got ps_count - $var_ps_count ng_count - $var_ng_count" $option_debug_append_text

		if [[ $var_ps_count -gt 0 && $var_ng_count -gt 0 ]]; then
			#TODO: Need to add logic to handle this case
			_debug "Need to add logic to handle this case" $option_debug_append_text
		elif [[ $var_ng_count -gt 0 ]]; then
			for ((var_x=0;var_x<${#g_var_payees_index[@]};var_x++)) do
				var_payee_index=$(( ${g_var_payees_index[$var_x]}-1 ))
				for ((var_i=0;var_i<$g_var_count;var_i++)) do
					for ((var_j=0;var_j<$g_var_count;var_j++)) do
						if [[ $var_i -eq $var_payee_index ]]; then
							for ((var_k=0;var_k<$var_share_count;var_k++)) do
								if [[ $var_j -eq $(( ${g_var_share[$var_k]}-1 )) ]]; then
									#TODO: Add logic to handle this case
									_debug "Add logic to handle this case" $option_debug_append_text #TODO: Remove this line
								fi
							done
						else
							break
						fi
					done
				done
			done
		else
			_show_error "This case is not possible and should not occur"
		fi
		#TODO: Add code to handle unequal split
		_show_error "Functionality not yet added, please try later" #TODO: Remove this line after func added
		clear_global_vars #TODO: Remove this line after testing functionality
		draw_menu #TODO: Remove this line after testing functionality
	fi

	# TIP: This code was commented using regex in vim, under command mode
	# Shift + V - Select the section
	# Type :s/^/# - To comment the block selected
	# Type :s/^#// - To uncomment the block selected
#	_debug "Printing the table values as follows" $option_debug_append_text
#	for ((var_i=0;var_i<$g_var_count;var_i++)) do
#		for ((var_j=0;var_j<$g_var_count;var_j++)) do
#			_debug "Table [ $var_i, $var_j ] = ${g_var_table[$var_i,$var_j]}" $option_debug_append_text
#		done
#	done
}

# Read who are sharing the particular expense incured
function pick_persons {
	local var_i=0
	local var_cmd=""
	local var_share_len=0

	# Compute the total amount from all persons
	while [[ var_i -lt ${#g_var_payees_amt[@]} ]]
	do
		g_var_expense=$(echo "$msg_general_scale; $g_var_expense + ${g_var_payees_amt[$var_i]}" | bc)
		(( var_i++ ))
	done

	# Ask user for person(s) who share the total expense
	var_cmd="dialog --stdout --separate-output --cancel-label \"$msg_label_back\" --backtitle \"$msg_general_title\" --title \"****** PICK PERSONS ******\" --checklist \"Select the person(s) who share $g_var_currency_prefix$g_var_expense$g_var_currency_suffix\" 20 60 5"
	var_i=1
	while [[ var_i -le $g_var_count ]]
	do
		var_cmd="$var_cmd \"$var_i\" \"${g_var_persons[$(( $var_i-1 ))]}\" OFF"
		(( var_i++ ))
	done
	g_var_share=(`eval $var_cmd`)
	validate_keystroke $? $FUNCNAME get_total_expense

	# Make sure we have atleast two persons to share the expense
	var_share_len=${#g_var_share[@]}
	if [[ $var_share_len -eq 0 || $var_share_len -eq 1 ]]; then
		_show_error "$msg_err_min_share_count"
		$FUNCNAME
	else
		# Do individual person(s) share calculation
		do_share_calculation

		# After calculation add the details to log
		_write_log "[$g_var_date] $g_var_currency_prefix$g_var_expense$g_var_currency_suffix for \"$g_var_desc\" is shared among \"" $option_log_no_newline
		for ((var_i=0;var_i<${#g_var_share[@]};var_i++)) do
			if [[ $var_i -ne 0 ]]; then
				_write_log ", " $option_log_no_newline
			fi
#			if [[ $var_i -eq $(( ${g_var_share[$var_i]}-1 )) ]]; then
#				_write_log "${g_var_persons[$var_i]}" $option_log_no_newline
#			fi
			_write_log "${g_var_persons[$(( ${g_var_share[$var_i]}-1 ))]}" $option_log_no_newline
		done
		_write_log "\"" $option_log_add_newline
	fi

	# Show success message and return to menu
	_show_message "$msg_info_add_success"
	clear_global_vars
	draw_menu
}

# Read total expense incured for a particular cause
function get_total_expense {
	local var_i=0
	local var_ret=0
	local var_count=0
	local var_index=0
	local var_expense=0
	local var_date=""
	local var_desc=""
	local var_cmd=""

	# If date is not initialized then get current date
	if [[ ${#g_var_date} -eq 0 ]]; then
		g_var_date=`date +%d`/`date +%m`/`date +%Y`
	fi

	# For every person selected initialize their amount
	while [[ var_i -lt ${#g_var_payees_index[@]} ]]
	do
		if [[ -z ${g_var_payees_amt[$var_i]} ]]; then
			g_var_payees_amt[$var_i]=0
		fi
		(( var_i++ ))
	done

	# Get all the required details from user
	var_cmd="dialog --stdout --extra-button --extra-label \"$msg_label_pickdate\" --cancel-label \"$msg_label_back\" --backtitle \"$msg_general_title\" --title \"****** EXPENSE DETAILS ******\" --mixedform \"Enter the following details\" 18 60 0 \"Trip Date: \" 1 1 \"$g_var_date\" 1 20 20 0 2 \"Short description: \" 2 1 \"$g_var_desc\" 2 20 120 0 0 \"Add following person(s) expense amount: \" 3 1 \"\" 3 0 0 0 0"
	var_i=0
	while [[ var_i -lt ${#g_var_payees_index[@]} ]]
	do
		var_index=$(( ${g_var_payees_index[$var_i]}-1 ))
		var_cmd="$var_cmd \"${g_var_persons[$var_index]} :\" $(( $var_i+4 )) 1 \"${g_var_payees_amt[$var_i]}\" $(( $var_i+4 )) 20 10 0 0"
		(( var_i++ ))
	done
	var_cmd="$var_cmd > .tmp"
	eval $var_cmd
	var_ret=$?

	# If user tries to change date then we land here
	if [[ $var_ret  -eq 3 ]]; then
		local var_day=`echo $g_var_date | cut -d'/' -f1`
		local var_month=`echo $g_var_date | cut -d'/' -f2`
		local var_year=`echo $g_var_date | cut -d'/' -f3`
		var_ret=`dialog --stdout --no-cancel --backtitle "$msg_general_title" --title "****** TRIP DATE ******" --calendar "Pick trip date:" 0 0 $var_day $var_month $var_year`
		validate_keystroke $? $FUNCNAME $FUNCNAME
		g_var_date=$var_ret
		$FUNCNAME
	fi
	validate_keystroke $var_ret $FUNCNAME draw_menu

	# So far everything went fine, read all required
	# data and add to respective field to proceed further
	var_i=0
	while IFS= read -r line
	do
    	if [[ $var_count -eq 0 ]]; then
			# Read date
        	var_date=$line
    	elif [[ $var_count -eq 1 ]]; then
			# Read description for expense and validate
        	var_desc=$line
			if [[ ${#var_desc} -eq 0 ]]; then
				_show_error "$msg_err_missing_description"
				$FUNCNAME
			fi
			g_var_desc=$var_desc
    	else
			# Read person(s) paid amounts and validate
			var_expense=$line
			var_ret=$(validate_expense $var_expense)
			if [[ $var_ret -eq $ret_err_invalid_expense ]] || [[ $var_expense -eq 0 ]]; then
				_show_error "$msg_err_invalid_expense"
				$FUNCNAME
			else
				g_var_payees_amt[$var_i]=$var_expense
				(( var_i++ ))
			fi
    	fi
    	let var_count++
	done <".tmp"

	rm -f .tmp > /dev/null 2>&1
	pick_persons
}

# Read trip expense incured
function add_trip_expense {
	local var_i=1
	local var_payee_count=0
	local var_cmd="dialog --stdout --separate-output --cancel-label \"$msg_label_back\" --backtitle \"$msg_general_title\" --title \"****** PICK PERSONS ******\" --checklist \"Select the person(s) who made payment\" 20 60 5"
	while [[ var_i -le $g_var_count ]]
	do
		var_cmd="$var_cmd \"$var_i\" \"${g_var_persons[$(( $var_i-1 ))]}\" OFF"
		(( var_i++ ))
	done
	g_var_payees_index=(`eval $var_cmd`)
	validate_keystroke $? $FUNCNAME draw_menu

	# Make sure we have atleast one person selected
	var_payee_count=${#g_var_payees_index[@]}
	if [[ $var_payee_count -eq 0 ]]; then
		_show_error "$msg_err_need_payee"
		$FUNCNAME
	fi
	get_total_expense
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
	if [ -f .$g_var_rndnum.log ]; then
		dialog --stdout --exit-label "$msg_label_back" --backtitle "$msg_general_title" --title "****** LOG ******" --textbox .$g_var_rndnum.log 30 60
	else
		_show_message "$msg_info_empty_log"
	fi
	validate_keystroke $? draw_menu draw_menu
	draw_menu
}

# Compute indiviual share
function show_individual_share {
	local var_i=1
	local var_amt=0
	local var_req=""

	rm -f .$g_var_rndnum.calc > /dev/null 2>&1
	if [ -f .$g_var_rndnum.log ]; then
		# Nothing to do here proceed freely
		echo "" > .$g_var_rndnum.calc
	else
		_show_message "$msg_info_empty_log"
		validate_keystroke $? draw_menu draw_menu
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
	validate_keystroke $? $FUNCNAME draw_menu

	# We got the person, do calculation and write it to file
	if [[ $var_req -eq 0 ]]; then
		_show_error "$msg_err_pick_indiv"
		validate_keystroke $? draw_menu draw_menu
		$FUNCNAME
	else
		for ((var_i=0;var_i<$g_var_count;var_i++)) do
			if [[ $var_i -eq $(( $var_req-1 )) ]]; then
				continue
			else
				if [[ $(echo "$msg_general_scale; ${g_var_table[$(( $var_req-1 )),$var_i]} == ${g_var_table[$var_i,$(( $var_req-1 ))]}" | bc) -eq 1 ]]; then
					echo "\"${g_var_persons[$(( $var_req-1 ))]}\" has to give/get nothing to/from \"${g_var_persons[$var_i]}\"" >> .$g_var_rndnum.calc
				elif [[ $(echo "$msg_general_scale; ${g_var_table[$(( $var_req-1 )),$var_i]} > ${g_var_table[$var_i,$(( var_req-1 ))]}" | bc) -eq 1 ]]; then
					var_amt=$(echo "$msg_general_scale; ${g_var_table[$(( $var_req-1 )),$var_i]} - ${g_var_table[$var_i,$(( var_req-1 ))]}" | bc)
					echo "\"${g_var_persons[$(( $var_req-1 ))]}\" has to get $g_var_currency_prefix$var_amt$g_var_currency_suffix from \"${g_var_persons[$var_i]}\"" >> .$g_var_rndnum.calc
				else
					var_amt=$(echo "$msg_general_scale; ${g_var_table[$var_i,$(( $var_req-1 ))]} - ${g_var_table[$(( $var_req-1 )),$var_i]}" | bc)
					echo "\"${g_var_persons[$(( $var_req-1 ))]}\" has to give $g_var_currency_prefix$var_amt$g_var_currency_suffix to \"${g_var_persons[$var_i]}\"" >> .$g_var_rndnum.calc
				fi
			fi
		done
	fi

	# Read the file and show the content to user
	dialog --stdout --exit-label "$msg_label_back" --backtitle "$msg_general_title" --title "****** SHARE ******" --textbox .$g_var_rndnum.calc 30 60
	validate_keystroke $? draw_menu draw_menu
	draw_menu
}

# Show menu for the user to choose between various options
function draw_menu {
	local var_ret=0
	var_ret=`dialog --stdout --cancel-label "$msg_label_back" --backtitle "$msg_general_title" --title "****** MENU ******" --menu "Please choose one of the following option:" 20 60 5 \
	                      1 "Add trip details (Equal split)" \
	                      2 "Show individual share" \
	                      3 "Show details log" \
	                      4 "Show author name" \
	                      5 "Exit this program"`
	validate_keystroke $? $FUNCNAME get_person_names
	if [[ $var_ret -eq 1 ]]; then
		add_trip_expense
	elif [[ $var_ret -eq 2 ]]; then
		show_individual_share
	elif [[ $var_ret -eq 3 ]]; then
		show_detail_log
	elif [[ $var_ret -eq 4 ]]; then
		show_author_name
	elif [[ $var_ret -eq 5 ]]; then
		_show_exit_message $FUNCNAME
	else
		echo "This case is not possible with ret: $var_ret"
	fi
}

# Get individual person name for proceeding further
function get_person_names {
	local var_i=1
	local var_j=0
	local var_cmd="dialog --stdout --cancel-label \"$msg_label_back\" --backtitle \"$msg_general_title\" --title \"****** ENTER PERSON DETAILS ******\" --form \"Enter individual name in following field:\" 18 60 0"
	while [[ var_i -le $g_var_count ]]
	do
		var_cmd="$var_cmd \"Person$var_i Name: \" $var_i 1 \"${g_var_persons[$(( $var_i-1 ))]}\" $var_i 20 20 0"
		(( var_i++ ))
	done

	# Modify IFS so that we can read person name containing space as well
	IFS=$'\n'
	g_var_persons=(`eval $var_cmd`)
	validate_keystroke $? $FUNCNAME get_person_count
	unset IFS

	while [[ var_j -lt $g_var_count ]]
	do
		if [[ ${#g_var_persons[$var_j]} -eq 0 ]];
		then
			_show_error "$msg_err_empty_name"
			$FUNCNAME
		fi
		(( var_j++ ))
	done

	# Once we have person names initialize table and draw menu
	do_table_init
	draw_menu
}

# Read number of persons involved in the trip
function get_person_count {
	g_var_count=`dialog --stdout --nocancel --backtitle "$msg_general_title" --title "****** PERSON COUNT ******" --inputbox "Enter no. of persons involved in the trip (for now max $g_var_maxcount): " 10 50`
	validate_keystroke $? $FUNCNAME $FUNCNAME
	local var_ret=$(validate_count $g_var_count)

	if [[ $var_ret -eq $ret_err_invalid_input ]]; then
		_show_error "$msg_err_invalid_input"
		$FUNCNAME
	else
		if [[ $g_var_count -eq 0 ]] || [[ $g_var_count -eq 1 ]]; then
			# We got value which makes no sense
			_show_error "$msg_err_invalid_number"
			$FUNCNAME
		elif [[ $g_var_count -gt $g_var_maxcount ]]; then
			# We got value which we can't handle now
			_show_error "$msg_err_max_exceeded"
			$FUNCNAME
		else
			get_person_names
		fi
	fi
}

# Welcome message
function welcome_message {
	# I agree its not a very warm welcome, but still we start with greetings
	dialog --colors --no-collapse --backtitle "$msg_general_title" --msgbox "       Welcome to \ZuTES\ZU\n( \ZbT\ZBrip \ZbE\ZBxpense \ZbS\ZBplitter )" 0 0
	get_person_count
}

# Trap handler
function trap_handler {
	# User wish to quit, so show message and die
	_show_auto_close_message "$msg_info_onexit"
	perform_cleanup
	clear
	exit
}

# Make sure we have the tools to finish the job at hand
function check_prerequisite {
	local var_fail=0
	local var_tput_found=0
	local var_writeprm_notfound=0
	local var_dialog_notfound=0
	local var_bc_notfound=0

	# If 'tput' is available then we can make use of it to show
	# colorful information to user to make it readable
	tput -V > /dev/null 2>&1
	if [[ $? -eq 0 ]]; then
		var_tput_found=1
	fi
	# Show license first then proceed
	echo "TES  Copyright (C) 2014  BalaC"
	echo "This program comes with ABSOLUTELY NO WARRANTY;"
	echo "This is free software, and you are welcome to redistribute it"
	echo "under certain conditions;"
	echo ""
	echo "=========================================================="
	echo "#### INITIATING PREREQUISITE CHECK TO RUN APPLICATION ####"
	echo "=========================================================="
	if [[ $var_tput_found -eq 1 ]]; then
		echo "$(tput bold)$(tput setaf 7)"
	fi

	# We need permission to create files under current directory
	# as we need to use few files for logging and calculation
	# purposes, lets check that one first
	touch $g_var_rndnum > /dev/null 2>&1
	if [[ $? -eq 0 ]]; then
		if [[ $var_tput_found -eq 1 ]]; then
			echo "$(tput setaf 2)"
		fi
		echo "Checking for write permission in current directory .... [   FOUND   ]"
		rm -f $g_var_rndnum > /dev/null 2>&1
		if [[ $var_tput_found -eq 1 ]]; then
			echo "$(tput setaf 7)"
		fi
	else
		if [[ $var_tput_found -eq 1 ]]; then
			echo "$(tput setaf 1)"
		fi
		echo "Checking for write permission in current directory .... [ NOT FOUND ]"
		var_writeprm_notfound=1
		var_fail=1
		if [[ $var_tput_found -eq 1 ]]; then
			echo "$(tput setaf 7)"
		fi
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
		if [[ $var_writeprm_notfound -eq 1 ]]; then
			echo "Script can't create intermitent files in current directory"
			echo "Please adjust the permission in such a way that script can"
			echo "create few temporary files which is required for its"
			echo "internal usage and doing calculations "
		fi	
		if [[ $var_dialog_notfound -eq 1 || $var_bc_notfound -eq 1 ]]; then
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
		fi
	else
		# Install trap handler for INT signal alone
		trap trap_handler INT
		welcome_message
	fi
}

# Everything needs a starting point and here is ours
check_prerequisite
