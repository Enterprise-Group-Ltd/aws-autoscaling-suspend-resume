#! /bin/bash
#
#
# ------------------------------------------------------------------------------------
#
# MIT License
# 
# Copyright (c) 2017 Enterprise Group, Ltd.
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# ------------------------------------------------------------------------------------
# 
# File: aws-asg-suspend-resume.sh
#
script_version=1.0.72  
#
#  Dependencies:
#  - bash shell
#  - jq - JSON wrangler https://stedolan.github.io/jq/
#  - AWS CLI tools (pre-installed on AWS AMIs) 
#  - AWS CLI profile with IAM permissions for the following AWS CLI commands:
#    * autoscaling describe-auto-scaling-groups
#    * autoscaling suspend-processes
#    * autoscaling resume-processes
#    * sts get-caller-identity
#
#
# Tested on: 
#   Windows Subsystem for Linux (WSL) 
#     OS Build: 15063.540
#     bash.exe version: 10.0.15063.0
#     Ubuntu 16.04
#     GNU bash, version 4.3.48(1)
#     jq 1.5-1-a5b5cbe
#     aws-cli/1.11.134 Python/2.7.12 Linux/4.4.0-43-Microsoft botocore/1.6.1
#   
#   AWS EC2
#     Amazon Linux AMI release 2017.03 
#     Linux 4.9.43-17.38.amzn1.x86_64 
#     GNU bash, version 4.2.46(2)
#     jq-1.5
#     aws-cli/1.11.133 Python/2.7.12 Linux/4.9.43-17.38.amzn1.x86_64 botocore/1.6.0
#
#
# By: Douglas Hackney
#     https://github.com/dhackney   
# 
# Type: AWS utility
# Description: 
#   This shell script suspends or resumes autoscaling group processes
#
#
# Roadmap:
# * add -r region
# * add -r all regions
# 
# 
#
###############################################################################
# 
# set the environmental variables 
#
set -o pipefail 
#
###############################################################################
# 
# initialize the script variables 
#
asg_modify_action=""
asg_modify_action_name=""
autoscaling_group_name=""
choices=""
cli_profile=""
count_asg_modify_process=0
count_cli_profile=0
count_error_lines=0
count_script_version_length=0
count_text_header_length=0
count_text_block_length=0
count_text_width_menu=0
count_text_width_header=0
count_text_side_length_menu=0
count_text_side_length_header=0
count_text_bar_menu=0
count_text_bar_header=0
count_this_file_tasks=0
counter_asg_modify_process=0
counter_report=0
counter_this_file_tasks=0
date_file=="$(date +"%Y-%m-%d-%H%M%S")"
date_now="$(date +"%Y-%m-%d-%H%M%S")"
_empty=""
_empty_task=""
_empty_task_sub=""
error_line_aws=""
error_line_pipeline=""
feed_write_log=""
filebytes_asg_list_asg_modify_process_txt=0
_fill=""
_fill_task=""
_fill_task_sub=""
full_path=""
let_done=""
let_done_task=""
let_done_task_sub=""
let_left=""
let_left_task=""
let_left_task_sub=""
let_progress=""
let_progress_task=""
let_progress_task_sub=""
list_asg_modify_process=""
logging=""
parameter1=""
paramter2=""
text_header=""
text_bar_menu_build=""
text_bar_header_build=""
text_side_menu=""
text_side_header=""
text_menu=""
text_menu_bar=""
text_header=""
text_header_bar=""
this_aws_account=""
this_aws_account_alias=""
this_file=""
this_log=""
thislogdate=""
this_log_file=""
this_log_file_errors=""
this_log_file_errors_full_path=""
this_log_file_full_path=""
this_log_temp_file_full_path=""
this_path=""
this_summary_report=""
this_summary_report_full_path=""
this_user=""
verbose=""
write_path=""
#
###############################################################################
# 
#
# load the baseline variables
#
this_utility_acronym="asg"
this_utility_filename_plug="asg-process"
this_path="$(pwd)"
this_file="$(basename "$0")"
full_path="${this_path}"/"$this_file"
this_log_temp_file_full_path="$this_path"/aws-"$this_utility_filename_plug"-log-temp.log 
this_user="$(whoami)"
date_file="$(date +"%Y-%m-%d-%H%M%S")"
count_this_file_tasks="$(cat "$full_path" | grep -c "\-\-\- begin\: " )"
counter_this_file_tasks=0
logging="n"
#
###############################################################################
# 
# initialize the temp log file
#
echo "" > "$this_log_temp_file_full_path"
#
#
##############################################################################################################33
#                           Function definition begin
##############################################################################################################33
#
#
# Functions definitions
#
#######################################################################
#
#
# function to display the usage
#
function fnUsage()
{
    echo ""
    echo " ---------------------------------- AWS Autoscale Suspend / Resume utility usage -------------------------------------"
    echo ""
    echo " This utility suspends or resumes Autoscaling Group processes  "  
    echo ""
    echo " This script will: "
    echo " * Suspend the processes in one or more Autoscaling Group(s) "
    echo " * Resume the processes in one or more Autoscaling Group(s) "
    echo ""
    echo "----------------------------------------------------------------------------------------------------------------------"
    echo ""
    echo " usage:"
    echo "        aws-asg-suspend-resume.sh -a u -n all -p myAWSCLIprofile "
    echo ""   
    echo "        Optional parameters: -b y -g y "
    echo ""
    echo " Where: "
    echo "  -a - Modification action to apply - suspend or resume autoscaling. Enter s for suspend or u for resume. "
    echo "         Example: -a u "
    echo ""
    echo "  -n - Name of the Autoscaling Group(s) to suspend or resume. Enter partial text to match similar "
    echo "       Autoscaling Group names. Enter 'all' for all Autoscaling Groups."
    echo "         Example: -n myAutoscalingGroupName "
    echo "         Example: -n myAuto "
    echo "         Example: -n all "
    echo ""    
    echo "  -p - Name of the AWS CLI cli_profile (i.e. what you would pass to the --profile parameter in an AWS CLI command)"
    echo "         Example: -p myAWSCLIprofile "
    echo ""    
    echo "  -b - Verbose console output. Set to 'y' for verbose console output. Note: verbose mode can be slow."
    echo "         Example: -b y "
    echo ""
    echo "  -g - Logging on / off. Default is off. Set to 'y' to create a debug log. Note: logging mode can be slower. "
    echo "         Example: -g y "
    echo ""
    echo "  -h - Display this message"
    echo "         Example: -h "
    echo ""
    echo "  ---version - Display the script version"
    echo "         Example: --version "
    echo ""
    echo ""
    exit 1
}
#
#######################################################################
#
#
# function to echo the progress bar to the console  
#
# source: https://stackoverflow.com/questions/238073/how-to-add-a-progress-bar-to-a-shell-script
#
# 1. Create ProgressBar function
# 1.1 Input is currentState($1) and totalState($2)
function fnProgressBar() 
{
# Process data
        let _progress=(${1}*100/"${2}"*100)/100
        let _done=(${_progress}*4)/10
        let _left=40-"$_done"
# Build progressbar string lengths
        _fill="$(printf "%${_done}s")"
        _empty="$(printf "%${_left}s")"
#
# 1.2 Build progressbar strings and print the ProgressBar line
# 1.2.1 Output example:
# 1.2.1.1  Progress : [########################################] 100%
printf "\r          Overall Progress : [${_fill// /#}${_empty// /-}] ${_progress}%%"
}
#
#######################################################################
#
#
# function to update the task progress bar   
#
# source: https://stackoverflow.com/questions/238073/how-to-add-a-progress-bar-to-a-shell-script
#
# 1. Create ProgressBar function
# 1.1 Input is currentState($1) and totalState($2)
function fnProgressBarTask() 
{
# Process data
        let _progress_task=(${1}*100/"${2}"*100)/100
        let _done_task=(${_progress_task}*4)/10
        let _left_task=40-"$_done_task"
# Build progressbar string lengths
        _fill_task="$(printf "%${_done_task}s")"
        _empty_task="$(printf "%${_left_task}s")"
#
# 1.2 Build progressbar strings and print the ProgressBar line
# 1.2.1 Output example:
# 1.2.1.1  Progress : [########################################] 100%
printf "\r             Task Progress : [${_fill_task// /#}${_empty_task// /-}] ${_progress_task}%%"
}
#
#######################################################################
#
#
# function to update the subtask progress bar   
#
# source: https://stackoverflow.com/questions/238073/how-to-add-a-progress-bar-to-a-shell-script
#
# 1. Create ProgressBar function
# 1.1 Input is currentState($1) and totalState($2)
function fnProgressBarTaskSub() 
{
# Process data
        let _progress_task_sub=(${1}*100/"${2}"*100)/100
        let _done_task_sub=(${_progress_task_sub}*4)/10
        let _left_task_sub=40-"$_done_task_sub"
# Build progressbar string lengths
        _fill_task_sub="$(printf "%${_done_task_sub}s")"
        _empty_task_sub="$(printf "%${_left_task_sub}s")"
#
# 1.2 Build progressbar strings and print the ProgressBar line
# 1.2.1 Output example:
# 1.2.1.1  Progress : [########################################] 100%
printf "\r         Sub-Task Progress : [${_fill_task_sub// /#}${_empty_task_sub// /-}] ${_progress_task_sub}%%"
}
#
#######################################################################
#
#
# function to display the task progress bar on the console  
#
# parameter 1 = counter
# paramter 2 = count
# 
function fnProgressBarTaskDisplay() 
{
    fnWriteLog ${LINENO} level_0 " ---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 "" 
    fnProgressBarTask "$1" "$2"
    fnWriteLog ${LINENO} level_0 "" 
    fnWriteLog ${LINENO} level_0 "" 
    fnWriteLog ${LINENO} level_0 " ---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
}
#
#######################################################################
#
#
# function to display the task progress bar on the console  
#
# parameter 1 = counter
# paramter 2 = count
# 
function fnProgressBarTaskSubDisplay() 
{
    fnWriteLog ${LINENO} level_0 " ---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 "" 
    fnProgressBarTaskSub "$1" "$2"
    fnWriteLog ${LINENO} level_0 "" 
    fnWriteLog ${LINENO} level_0 "" 
    fnWriteLog ${LINENO} level_0 " ---------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
}
#
#######################################################################
#
#
# function to echo the header to the console  
#
function fnHeader()
{
    clear
    fnWriteLog ${LINENO} level_0 "" 
    fnWriteLog ${LINENO} "--------------------------------------------------------------------------------------------------------------------"    
    fnWriteLog ${LINENO} "--------------------------------------------------------------------------------------------------------------------" 
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "$text_header"    
    fnWriteLog ${LINENO} level_0 "" 
    fnProgressBar ${counter_this_file_tasks} ${count_this_file_tasks}
    fnWriteLog ${LINENO} level_0 "" 
    fnWriteLog ${LINENO} level_0 "" 
    fnWriteLog ${LINENO} level_0 "$text_header_bar"
    fnWriteLog ${LINENO} level_0 ""
}
#
#######################################################################
#
#
# function to echo to the console and write to the log file 
#
function fnWriteLog()
{
    # clear IFS parser
    IFS=
    # write the output to the console
    fnOutputConsole "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"
    # if logging is enabled, then write to the log
    if [[ ("$logging" = "y") || ("$logging" = "z") ]] ;
        then
            # write the output to the log
            fnOutputLog "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"
    fi 
    # reset IFS parser to default values 
    unset IFS
}
#
#######################################################################
#
#
# function to echo to the console  
#
function fnOutputConsole()
{
    #
    # console output section
    #
    # test for verbose
    if [ "$verbose" = "y" ] ;  
        then
            # if verbose console output then
            # echo everything to the console
            #
            # strip the leading 'level_0'
                if [ "$2" = "level_0" ] ;
                    then
                        # if the line is tagged for display in non-verbose mode
                        # then echo the line to the console without the leading 'level_0'     
                        echo " Line: "$1" "$3" "$4" "$5" "$6" "$7" "$8" "$9""
                    else
                        # if a normal line echo all to the console
                        echo " Line: "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9""
                fi
    else
        # test for minimum console output
        if [ "$2" = "level_0" ] ;
            then
                # echo ""
                # echo "console output no -v: the logic test for level_0 was true"
                # echo ""
                # if the line is tagged for display in non-verbose mode
                # then echo the line to the console without the leading 'level_0'     
                echo " "$3" "$4" "$5" "$6" "$7" "$8" "$9""
        fi
    fi
    #
    #

}  

#
#######################################################################
#
#
# function to write to the log file 
#
function fnOutputLog()
{
    # log output section
    #
    # load the timestamp
    thislogdate="$(date +"%Y-%m-%d-%H:%M:%S")"
    #
    # ----------------------------------------------------------
    #
    # normal logging
    # 
    # append the line to the log variable
    # the variable is written to the log file on exit by function fnWriteLogFile
    #
    # if the script is crashing then comment out this section and enable the
    # section below "use this logging for debug"
    #
        if [ "$2" = "level_0" ] ;
            then
                # if the line is tagged for logging in non-verbose mode
                # then write the line to the log without the leading 'level_0'     
                this_log+="$(echo "${thislogdate} Line: "$1" "$3" "$4" "$5" "$6" "$7" "$8" "$9"" 2>&1)" 
            else
                # if a normal line write the entire set to the log
                this_log+="$(echo "${thislogdate} Line: "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"" 2>&1)" 
        fi
        #
        # append the new line  
        # do not quote the following variable: $'\n'
        this_log+=$'\n'
        #
    #  
    # ---------------------------------------------------------
    #
    # 'use this for debugging' - debug logging
    #
    # if the script is crashing then enable this logging section and 
    # comment out the prior logging into the 'this_log' variable
    #
    # note that this form of logging is VERY slow
    # 
    # write to the log file with a prefix timestamp 
    # echo "${thislogdate} Line: "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"" 2>&1 >> "$this_log_file_full_path"  
    #
    #
}
#
#######################################################################
#
#
# function to append the log variable to the temp log file 
#
function fnWriteLogTempFile()
{
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "Appending the log variable to the temp log file"
    fnWriteLog ${LINENO} "" 
    echo "$this_log" >> "$this_log_temp_file_full_path"
    # empty the temp log variable
    this_log=""
}
#
#######################################################################
#
#
# function to write log variable to the log file 
#
function fnWriteLogFile()
{
    # append the temp log file onto the log file
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} "Writing temp log to log file"
    fnWriteLog ${LINENO} "Value of variable 'this_log_temp_file_full_path': "
    fnWriteLog ${LINENO} "$this_log_temp_file_full_path"
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "Value of variable 'this_log_file_full_path': "
    fnWriteLog ${LINENO} "$this_log_file_full_path"
    fnWriteLog ${LINENO} level_0 ""   
    # write the contents of the variable to the temp log file
    fnWriteLogTempFile
    cat "$this_log_temp_file_full_path" >> "$this_log_file_full_path"
    echo "" >> "$this_log_file_full_path"
    echo "Log end" >> "$this_log_file_full_path"
    # delete the temp log file
    rm -f "$this_log_temp_file_full_path"
}
#
##########################################################################
#
#
# function to delete the work files 
#
function fnDeleteWorkFiles()
{
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "in delete work files "
    fnWriteLog ${LINENO} "value of variable 'verbose': "$verbose" "
    fnWriteLog ${LINENO} ""
        if [ "$verbose" != "y" ] ;  
            then
                # if not verbose console output then delete the work files
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "In non-verbose mode: Deleting work files"
                fnWriteLog ${LINENO} ""
                feed_write_log="$(rm -f ./"$this_utility_acronym"-* 2>&1)"
                fnWriteLog ${LINENO} "$feed_write_log"
                feed_write_log="$(rm -f ./"$this_utility_acronym"_* 2>&1)"
                fnWriteLog ${LINENO} "$feed_write_log"
                fnWriteLog ${LINENO} ""
                fnWriteLog ${LINENO} "value of variable 'this_log_file_full_path' "$this_log_file_full_path" "
                fnWriteLog ${LINENO} "$feed_write_log"
                fnWriteLog ${LINENO} ""
                #
                # if no errors, then delete the error log file
                count_error_lines="$(cat "$this_log_file_errors_full_path" | wc -l)"
                if (( "$count_error_lines" < 3 ))
                    then
                        rm -f "$this_log_file_errors_full_path"
                fi  
            else
                # in verbose mode so preserve the work files 
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "In verbose mode: Preserving work files "
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "work files are here: "$this_path" "
                fnWriteLog ${LINENO} level_0 ""                
        fi       
}
#
##########################################################################
#
#
# function to log non-fatal errors 
#
function fnErrorLog()
{
    fnWriteLog ${LINENO} level_0 "-----------------------------------------------------------------------------------------------------"       
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " Error message: "
    fnWriteLog ${LINENO} level_0 " "$feed_write_log" "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "-----------------------------------------------------------------------------------------------------" 
    echo "-----------------------------------------------------------------------------------------------------" >> "$this_log_file_errors_full_path"         
    echo "" >> "$this_log_file_errors_full_path" 
    echo " Error message: " >> "$this_log_file_errors_full_path" 
    echo " "$feed_write_log"" >> "$this_log_file_errors_full_path" 
    echo "" >> "$this_log_file_errors_full_path"
    echo "-----------------------------------------------------------------------------------------------------" >> "$this_log_file_errors_full_path" 
}
#
##########################################################################
#
#
# function to handle command or pipeline errors 
#
function fnErrorPipeline()
{
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 " System Error while running the previous command or pipeline "
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 " Please check the error message above "
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 " Error at script line number: "$error_line_pipeline" "
            fnWriteLog ${LINENO} level_0 ""
            if [[ "$logging" == "y" ]] ;
                then 
                    fnWriteLog ${LINENO} level_0 " The log will also show the error message and other environment, variable and diagnostic information "
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 " The log is located here: "
                    fnWriteLog ${LINENO} level_0 " "$this_log_file_full_path""
            fi
            fnWriteLog ${LINENO} level_0 ""        
            fnWriteLog ${LINENO} level_0 " Exiting the script"
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "-----------------------------------------------------------------------------------------------------"
            fnWriteLog ${LINENO} level_0 ""
            # append the temp log onto the log file
            fnWriteLogTempFile
            # write the log variable to the log file
            fnWriteLogFile
            exit 1
}
#
##########################################################################
#
#
# function for AWS CLI errors 
#
function fnErrorAws()
{
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " AWS Error while executing AWS CLI command"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " Please check the AWS error message above "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " Error at script line number: "$error_line_aws" "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " The log will also show the AWS error message and other diagnostic information "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " The log is located here: "
    fnWriteLog ${LINENO} level_0 " "$this_log_file_full_path""
    fnWriteLog ${LINENO} level_0 ""        
    fnWriteLog ${LINENO} level_0 " Exiting the script"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    # append the temp log onto the log file
    fnWriteLogTempFile
    # write the log variable to the log file
    fnWriteLogFile
    exit 1
}
#
##########################################################################
#
#
# function for jq errors 
#
function fnErrorJq()
{
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " Error at script line number: "$error_line_jq" "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " There was a jq error while processing JSON "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " Please check the jq error message above "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " The log will also show the jq error message and other diagnostic information "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 " The log is located here: "
    fnWriteLog ${LINENO} level_0 " "$this_log_file_full_path""
    fnWriteLog ${LINENO} level_0 ""        
    fnWriteLog ${LINENO} level_0 " Exiting the script"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    # append the temp log onto the log file
    fnWriteLogTempFile
    # write the log variable to the log file
    fnWriteLogFile
    exit 1
}
#
##########################################################################
#
#
# function to increment the ASG modify process counter 
#
function fnCounterIncrementAsgModifyProcess()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "increment the ASG modify process counter: 'counter_asg_modify_process'"
    counter_asg_modify_process="$((counter_asg_modify_process+1))"
    fnWriteLog ${LINENO} "post-increment value of variable 'counter_asg_modify_process': "$counter_asg_modify_process" "
    fnWriteLog ${LINENO} ""
    #
}
#
##########################################################################
#
#
# function to increment the task counter 
#
function fnCounterIncrementTask()
{
    fnWriteLog ${LINENO} ""  
    fnWriteLog ${LINENO} "increment the task counter"
    counter_this_file_tasks="$((counter_this_file_tasks+1))" 
    fnWriteLog ${LINENO} "value of variable 'counter_this_file_tasks': "$counter_this_file_tasks" "
    fnWriteLog ${LINENO} "value of variable 'count_this_file_tasks': "$count_this_file_tasks" "
    fnWriteLog ${LINENO} ""
}
#
##########################################################################
#
#
# function to increment the report counter 
#
function fnCounterIncrementReport()
{
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "increment the report counter: 'counter_report'"
    counter_report="$((counter_report+1))"
    fnWriteLog ${LINENO} "post-increment value of variable 'counter_report': "$counter_report" "
    fnWriteLog ${LINENO} ""
    #
}
#
##############################################################################################################33
#                           Function definition end
##############################################################################################################33
#
# 
###########################################################################################################################
#
#
# enable logging to capture initial segments
#
logging="z"
# 
###########################################################################################################################
#
#
# build the menu and header text line and bars 
#
text_header='Autoscaling Group Suspend / Resume Utility v'
count_script_version_length=${#script_version}
count_text_header_length=${#text_header}
count_text_block_length=$(( count_script_version_length + count_text_header_length ))
count_text_width_menu=104
count_text_width_header=83
count_text_side_length_menu=$(( (count_text_width_menu - count_text_block_length) / 2 ))
count_text_side_length_header=$(( (count_text_width_header - count_text_block_length) / 2 ))
count_text_bar_menu=$(( (count_text_side_length_menu * 2) + count_text_block_length + 2 ))
count_text_bar_header=$(( (count_text_side_length_header * 2) + count_text_block_length + 2 ))
# source and explanation for the following use of printf is here: https://stackoverflow.com/questions/5799303/print-a-character-repeatedly-in-bash
text_bar_menu_build="$(printf '%0.s-' $(seq 1 "$count_text_bar_menu")  )"
text_bar_header_build="$(printf '%0.s-' $(seq 1 "$count_text_bar_header")  )"
text_side_menu="$(printf '%0.s-' $(seq 1 "$count_text_side_length_menu")  )"
text_side_header="$(printf '%0.s-' $(seq 1 "$count_text_side_length_header")  )"
text_menu="$(echo "$text_side_menu"" ""$text_header""$script_version"" ""$text_side_menu")"
text_menu_bar="$(echo "$text_bar_menu_build")"
text_header="$(echo " ""$text_side_header"" ""$text_header""$script_version"" ""$text_side_header")"
text_header_bar="$(echo " ""$text_bar_header_build")"
# 
###########################################################################################################################
#
#
# display initializing message
#
clear
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "$text_header"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 " This utility suspends or resumes AWS AutoScaling Group processes "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 " This script will: "
fnWriteLog ${LINENO} level_0 " - Suspend or resume the processes for Autoscaling Groups "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "$text_header_bar"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "                            Please wait  "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "  Checking the input parameters and initializing the app " 
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "  Depending on connection speed and AWS API response, this can take " 
fnWriteLog ${LINENO} level_0 "  from a few seconds to a few minutes "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "  Status messages and opening menu will appear below"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "$text_header_bar"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
# 
#
###################################################
#
#
# check command line parameters 
# check for -h
#
if [[ "$1" = "-h" ]] ; then
    clear
    fnUsage
fi
#
###################################################
#
#
# check command line parameters 
# check for --version
#
if [[ "$1" = "--version" ]] ; 
    then
        clear 
        echo ""
        echo "'AWS Autoscaling Group Suspend / Resume' utility script version: "$script_version" "
        echo ""
    exit 
fi
#
###################################################
#
#
# check command line parameters 
# if less than 2, then display the usage
#
if [[ "$#" -lt 6 ]] ; then
    clear
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "-------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "  ERROR: You did not enter all of the required parameters " 
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "  You must provide values for all three parameters: -p -a -n "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "  Example: "$0" -p MyProfileName -a s -n myAutoscalingGroupName "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "-------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    fnUsage
fi
#
###################################################
#
#
# check command line parameters 
# if too many parameters, then display the error message and useage
#
if [[ "$#" -gt 10 ]] ; then
    clear
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "-------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "  ERROR: You entered too many parameters" 
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "  You must provide only one value for all parameters: -p -a -n -b -g "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "  Example: "$0" -p MyProfileName -a r -n all -b y -g y "
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "-------------------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
    fnUsage
fi
#
###################################################
#
#
# parameter values 
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable '@': "$@" "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of parameter '1' "$1" "
fnWriteLog ${LINENO} "value of parameter '2' "$2" "
fnWriteLog ${LINENO} "value of parameter '3' "$3" "
fnWriteLog ${LINENO} "value of parameter '4' "$4" "
fnWriteLog ${LINENO} "value of parameter '5' "$5" "
fnWriteLog ${LINENO} "value of parameter '6' "$6" "
#
###################################################
#
#
# load the main loop variables from the command line parameters 
#
while getopts "p:a:n:b:g:h" opt; 
    do
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "value of variable '@': "$@" "
        fnWriteLog ${LINENO} "value of variable 'opt': "$opt" "
        fnWriteLog ${LINENO} "value of variable 'OPTIND': "$OPTIND" "
        fnWriteLog ${LINENO} ""   
        #     
        case "$opt" in
        p)
            cli_profile="$OPTARG"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of -p 'cli_profile': "$cli_profile" "
        ;;
        a)
            asg_modify_action="$OPTARG"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of -a 'asg_modify_action': "$asg_modify_action" "
        ;;
        n)
            autoscaling_group_name="$OPTARG"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of -n 'autoscaling_group_name': "$autoscaling_group_name" "
        ;;
        b)
            verbose="$OPTARG"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of -b 'verbose': "$verbose" "
        ;;  
        g)
            logging="$OPTARG"
            fnWriteLog ${LINENO} ""
            fnWriteLog ${LINENO} "value of -g 'logging': "$logging" "
        ;;  
        h)
            fnUsage
        ;;   
        \?)
            clear
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------"
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "  ERROR: You entered an invalid option." 
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "  Invalid option: -"$OPTARG""
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 ""
            fnWriteLog ${LINENO} level_0 "---------------------------------------------------------------------"
            fnWriteLog ${LINENO} level_0 ""
            fnUsage
        ;;
    esac
done
#
###################################################
#
#
# check logging variable 
#
#
###################################################
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable '@': "$@" "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'logging': "$logging" "
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "if logging not enabled by parameter, then disabling logging "
if [[ "$logging" != "y" ]] ;
    then
    logging="n" 
fi
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'logging': "$logging" "
fnWriteLog ${LINENO} ""
#
# parameter values 
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'cli_profile' "$cli_profile" "
fnWriteLog ${LINENO} "value of variable 'verbose' "$verbose" "
fnWriteLog ${LINENO} "value of variable 'logging' "$logging" "
#
###################################################
#
#
# disable logging if not set by the -g parameter 
#
if [[ "$logging" != "y" ]] ;
    then
        logging="n"
fi
#
###################################################
#
#
# check command line parameters 
# check for valid AWS CLI profile 
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "count the available AWS CLI profiles that match the -p parameter profile name "
count_cli_profile="$(cat /home/"$this_user"/.aws/config | grep -c "$cli_profile")"
# if no match, then display the error message and the available AWS CLI profiles 
if [[ "$count_cli_profile" -ne 1 ]]
    then
        clear
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  ERROR: You entered an invalid AWS CLI profile: "$cli_profile" " 
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  Available cli_profiles are:"
        cli_profile_available="$(cat /home/"$this_user"/.aws/config | grep "\[profile" 2>&1)"
        #
        # check for command / pipeline error(s)
        if [ "$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        fnWriteLog ${LINENO} "value of variable 'cli_profile_available': "$cli_profile_available ""
        feed_write_log="$(echo "  "$cli_profile_available"" 2>&1)"
        fnWriteLog ${LINENO} level_0 "$feed_write_log"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  To set up an AWS CLI profile enter: aws configure --profile profileName "
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  Example: aws configure --profile MyProfileName "
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------"
        fnWriteLog ${LINENO} level_0 ""
        fnUsage
fi 
#
#
###################################################
#
#
# pull the AWS account number
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "pulling AWS account"
this_aws_account="$(aws sts get-caller-identity --profile "$cli_profile" --output text --query 'Account')"
fnWriteLog ${LINENO} "value of variable 'this_aws_account': "$this_aws_account" "
fnWriteLog ${LINENO} ""
#
###################################################
#
#
# set the aws account dependent variables
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "setting the AWS account dependent variables"
#
write_path="$this_path"/aws-"$this_aws_account"-"$this_utility_filename_plug"-"$date_file"
this_log_file=aws-"$this_aws_account"-"$this_utility_filename_plug"-v"$script_version"-"$date_file"-debug.log 
this_log_file_errors=aws-"$this_aws_account"-"$this_utility_filename_plug"-v"$script_version"-"$date_file"-errors.log 
this_log_file_full_path="$write_path"/"$this_log_file"
this_log_file_errors_full_path="$write_path"/"$this_log_file_errors"
this_summary_report=aws-"$this_aws_account"-"$this_utility_filename_plug"-"$date_file"-summary-report.txt
this_summary_report_full_path="$write_path"/"$this_summary_report"
#
fnWriteLog ${LINENO} "value of variable 'write_path': "$write_path" "
fnWriteLog ${LINENO} "value of variable 'this_log_file': "$this_log_file" "
fnWriteLog ${LINENO} "value of variable 'this_log_file_errors': "$this_log_file_errors" "
fnWriteLog ${LINENO} "value of variable 'this_log_file_full_path': ""$this_log_file_full_path"" "
fnWriteLog ${LINENO} "value of variable 'this_log_file_errors_full_path': "$this_log_file_errors_full_path" "
fnWriteLog ${LINENO} "value of variable 'this_summary_report': "$this_summary_report" "
fnWriteLog ${LINENO} "value of variable 'this_summary_report_full_path': "$this_summary_report_full_path" "
fnWriteLog ${LINENO} ""
#
###################################################
#
#
# create the directories
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "creating write path directories "
feed_write_log="$(mkdir -p "$write_path" 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "status of write path directory "
feed_write_log="$(ls -ld */ "$this_path" 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
###################################################
#
#
# pull the AWS account alias
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "pulling AWS account alias"
this_aws_account_alias="$(aws iam list-account-aliases --profile "$cli_profile" --output text --query 'AccountAliases' )"
fnWriteLog ${LINENO} "value of variable 'this_aws_account_alias': "$this_aws_account_alias" "
fnWriteLog ${LINENO} ""
#
###############################################################################
# 
#
# Initialize the log file
#
if [[ "$logging" = "y" ]] ;
    then
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "initializing the log file "
        fnWriteLog ${LINENO} ""
        echo "Log start" > "$this_log_file_full_path"
        echo "" >> "$this_log_file_full_path"
        echo "This log file name: "$this_log_file"" >> "$this_log_file_full_path"
        echo "" >> "$this_log_file_full_path"
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "contents of file:'$this_log_file_full_path' "
        feed_write_log="$(cat "$this_log_file_full_path"  2>&1)"
        fnWriteLog ${LINENO} "$feed_write_log"
        fnWriteLog ${LINENO} ""
#
fi 
#
###############################################################################
# 
#
# Initialize the error log file
#
echo "  Errors:" > "$this_log_file_errors_full_path"
echo "" >> "$this_log_file_errors_full_path"
#
###############################################################################
# 
#
# Set the action name
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "setting the action name  "
if [[ "$asg_modify_action" = "u" ]] ;
    then
        asg_modify_action_name="resume"
        #
elif [[ "$asg_modify_action" = 's' ]] ;
    then
        asg_modify_action_name="suspend"
        #
fi
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'asg_modify_action_name': "$asg_modify_action_name"  "
fnWriteLog ${LINENO} ""
#
#
#
#
###########################################################################################################################
#
#
# Begin checks and setup 
#
#
#
###############################################################################
# 
#
# Test the -n value for valid ASGs
#

# test -n section goes here 

#
###############################################################################
# 
#
# pull the list and number of ASGs to modify
#
#
# pull a list of the ASGs
# 
fnWriteLog ${LINENO} "initializing the ASG variable 'list_asg_modify_process' "
list_asg_modify_process=""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'list_asg_modify_process':"
feed_write_log="$(echo "$list_asg_modify_process" 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "pulling the list of ASGs to change"
#
for asg_name  
in $(aws autoscaling describe-auto-scaling-groups --profile "$cli_profile" --query 'AutoScalingGroups[*].AutoScalingGroupName' --output text) ; 
    do 
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "----------------------- loop head: pull ASG names -----------------------  "
        fnWriteLog ${LINENO} ""
        #
        fnWriteLog ${LINENO} ""       
        ## disabled for speed 
        ## enable for debugging     
        # fnWriteLog ${LINENO} "pre-append value of variable 'list_asg_modify_process':"
        # feed_write_log="$(echo "$list_asg_modify_process" 2>&1)"
        # fnWriteLog ${LINENO} "$feed_write_log"
        # fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "value of variable 'asg_name':"
        feed_write_log="$(echo "$asg_name" 2>&1)"
        fnWriteLog ${LINENO} "$feed_write_log"
        fnWriteLog ${LINENO} ""           
        fnWriteLog ${LINENO} "appending variable 'asg_name' to variable 'list_asg_modify_process':"
        list_asg_modify_process+="${asg_name}"
        # do not quote the following variable: $'\n'
        list_asg_modify_process+=$'\n'
        ## disabled for speed 
        ## enable for debugging     
        # fnWriteLog ${LINENO} ""
        # fnWriteLog ${LINENO} "post-append value of variable 'list_asg_modify_process':"
        # feed_write_log="$(echo "$list_asg_modify_process" 2>&1)"
        # fnWriteLog ${LINENO} "$feed_write_log"
        fnWriteLog ${LINENO} ""           
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "----------------------- loop tail: pull ASG names -----------------------  "
        fnWriteLog ${LINENO} ""
        #
    done 
#
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------- done: pull ASG names -----------------------  "
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "post-append, pre-filter value of variable 'list_asg_modify_process':"
feed_write_log="$(echo "$list_asg_modify_process" 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""           
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "filtering the list of ASGs to change if not all"
if [[ "$autoscaling_group_name" != "all" ]] ;
  then
        # matches the -n parameter anywhere in the ASG name
        list_asg_modify_process="$(echo "$list_asg_modify_process" | grep ".*"$autoscaling_group_name".*"  2>&1)"
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "post-filtered value of variable 'list_asg_modify_process':"
        feed_write_log="$(echo "$list_asg_modify_process" 2>&1)"
        fnWriteLog ${LINENO} "$feed_write_log"
        fnWriteLog ${LINENO} ""           
fi   
#
# write the variable to a file
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "writing variable 'list_asg_modify_process' to file: 'asg_list_asg_modify_process.txt' "
feed_write_log="$(echo "$list_asg_modify_process" > asg_list_asg_modify_process.txt 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} "contents of file: 'asg_list_asg_modify_process.txt' "
feed_write_log="$(cat asg_list_asg_modify_process.txt 2>&1)"
fnWriteLog ${LINENO} "$feed_write_log"
fnWriteLog ${LINENO} ""
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "counting the list of ASGs to change"
# test for empty file with only a line feed
filebytes_asg_list_asg_modify_process_txt="$(stat --printf="%s" asg_list_asg_modify_process.txt )" 
if [[ "$filebytes_asg_list_asg_modify_process_txt" -eq 1 ]] ;
    then 
        count_asg_modify_process=0
    else
        count_asg_modify_process="$(cat asg_list_asg_modify_process.txt | wc -l 2>&1 )"
fi
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "value of variable 'count_asg_names': "$count_asg_modify_process" "
fnWriteLog ${LINENO} ""  
#
###################################################
#
#
# check for zero ASGs to modify
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "checking for zero ASGs name match "
if [[ "$count_asg_modify_process" -eq 0 ]] ;
    then
        clear
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "-------------------------------------------------------------------------------------------------"
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "  ERROR: No AutoScaling Group name matched parameter: -n "$autoscaling_group_name" " 
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "-------------------------------------------------------------------------------------------------"
        fnWriteLog ${LINENO} level_0 ""
        fnUsage
fi
#
###################################################
#
#
# clear the console
#
clear
# 
######################################################################################################################################################################
#
#
# Opening menu
#
#
######################################################################################################################################################################
#
#
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "$text_menu"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 " Suspend / Resume AWS AutoScaling Group processes  "  
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "$text_menu_bar"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "AWS account:............"$this_aws_account"  "$this_aws_account_alias" "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "Autoscaling Group Process modification: "$asg_modify_action_name" "
fnWriteLog ${LINENO} level_0 ""
if [[ "$autoscaling_group_name" != "all" ]] ;
    then 
        fnWriteLog ${LINENO} level_0 "Autoscaling Group names matching or containing this text will be modified: "$autoscaling_group_name" "
    else  
        fnWriteLog ${LINENO} level_0 "All Autoscaling Groups will be modified "
fi
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "Count of Autoscaling Groups to "$asg_modify_action_name": "$count_asg_modify_process" "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "$text_menu_bar"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "The process modification >>"$asg_modify_action_name"<< will be applied to the Autoscaling Groups "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 " ###############################################"
fnWriteLog ${LINENO} level_0 " >> Note: There is no undo for this operation << "
fnWriteLog ${LINENO} level_0 " ###############################################"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 " By running this utility script you are taking full responsibility for any and all outcomes"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "Autoscaling Group Suspend / Resume utility"
fnWriteLog ${LINENO} level_0 "Run Utility Y/N Menu"
#
# Present a menu to allow the user to exit the utility and do the preliminary steps
#
# Menu code source: https://stackoverflow.com/questions/30182086/how-to-use-goto-statement-in-shell-script
#
# Define the choices to present to the user, which will be
# presented line by line, prefixed by a sequential number
# (E.g., '1) copy', ...)
choices=( 'Run' 'Exit' )
#
# Present the choices.
# The user chooses by entering the *number* before the desired choice.
select choice in "${choices[@]}"; do
#   
    # If an invalid number was chosen, "$choice" will be empty.
    # Report an error and prompt again.
    [[ -n "$choice" ]] || { fnWriteLog ${LINENO} level_0 "Invalid choice." >&2; continue; }
    #
    # Examine the choice.
    # Note that it is the choice string itself, not its number
    # that is reported in "$choice".
    case "$choice" in
        Run)
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "Running Autoscaling Group Suspend / Resume utility"
                fnWriteLog ${LINENO} level_0 ""
                # Set flag here, or call function, ...
            ;;
        Exit)
        #
        #
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 "Exiting the utility..."
                fnWriteLog ${LINENO} level_0 ""
                fnWriteLog ${LINENO} level_0 ""
                # delete the work files
                fnDeleteWorkFiles
                # append the temp log onto the log file
                fnWriteLogTempFile
                # write the log variable to the log file
                fnWriteLogFile
                exit 1
    esac
    #
    # Getting here means that a valid choice was made,
    # so break out of the select statement and continue below,
    # if desired.
    # Note that without an explicit break (or exit) statement, 
    # bash will continue to prompt.
    break
    #
    # end select - menu 
    # echo "at done"
done
#
##########################################################################
#
#      *********************  begin script *********************
#
##########################################################################
#
##########################################################################
#
#
# ---- begin: write the start timestamp to the log 
#
fnHeader
#
date_now="$(date +"%Y-%m-%d-%H%M%S")"
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "run start timestamp: "$date_now" " 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
fnWriteLog ${LINENO} ""
#
##########################################################################
#
#
# clear the console for the run 
#
fnHeader
#
##########################################################################
#
#
# ---- begin: display the log location 
#
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "Run log: "$this_log_file_full_path" " 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "" 
#
#
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
fnWriteLog ${LINENO} ""
#
##########################################################################
#
#
# Suspend / resume the ASGs
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "------------------------------------ begin: modify the ASG processes  ------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
# 
# set the counter
counter_asg_modify_process=0

#
for asg_name_modify in $list_asg_modify_process ; 
    do 
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "----------------------- loop head: modify ASG processes -----------------------  "
    fnWriteLog ${LINENO} ""
    #
    # display the header    
    fnHeader
    # display the task progress bar
    fnProgressBarTaskDisplay "$counter_asg_modify_process" "$count_asg_modify_process"
    #
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "This task takes a while. Please wait..."
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "Modifying processes to "$asg_modify_action_name" for Autoscaling Group: "
    fnWriteLog ${LINENO} level_0 "$asg_name_modify"
    fnWriteLog ${LINENO} ""   
    fnWriteLog ${LINENO} "AWS CLI command: aws autoscaling ${asg_modify_action_name}-processes --auto-scaling-group-name "$asg_name_modify" --profile "$cli_profile" "   
    feed_write_log="$(aws autoscaling ${asg_modify_action_name}-processes --auto-scaling-group-name "$asg_name_modify" --profile "$cli_profile" 2>&1)"
            #
            # check for errors from the AWS API  
            if [ "$?" -ne 0 ]
                then
                    # AWS Error while changing the ASG process status
                    fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"       
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "AWS error message: "
                    fnWriteLog ${LINENO} level_0 "$feed_write_log"
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 " AWS Error while changing the process status to "$asg_modify_action_name" for "$asg_name_modify" "
                    fnWriteLog ${LINENO} level_0 ""
                    fnWriteLog ${LINENO} level_0 "--------------------------------------------------------------------------------------------------"
                    #
                    # set the awserror line number
                    error_line_aws="$((${LINENO}-18))"
                    #
                    # call the AWS error handler
                    fnErrorAws
                    #
            fi # end non-recursive AWS error
            #
    fnWriteLog ${LINENO} "$feed_write_log"
    fnWriteLog ${LINENO} ""           
    #
    # increment the modify counter
    fnCounterIncrementAsgModifyProcess
    #
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "----------------------- loop tail: modify ASG processes -----------------------  "
    fnWriteLog ${LINENO} ""
    #
    # write out the temp log and empty the log variable
    fnWriteLogTempFile
    #
    done
    #
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "----------------------- done: modify ASG processes -----------------------  "
    fnWriteLog ${LINENO} ""
    #
#
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
fnWriteLog ${LINENO} ""
#
# display the header    
fnHeader
# display the task progress bar
fnProgressBarTaskDisplay "$counter_asg_modify_process" "$count_asg_modify_process"
#
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "Task 'modify AutoScaling Groups processes' complete"
fnWriteLog ${LINENO} level_0 ""
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "------------------------------------- end: modify the ASG processes  -------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
##########################################################################
#
#
# create the summary report 
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "--------------------- begin: print summary report for each Autoscaling Group name ------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnHeader
# load the report variables
#
# initialize the counters
#
#
fnWriteLog ${LINENO} ""
fnHeader
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "Creating job summary report file "
fnWriteLog ${LINENO} level_0 ""
# initialize the report file and append the report lines to the file
echo "">"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  ------------------------------------------------------------------------------------------">>"$this_summary_report_full_path"
echo "  ------------------------------------------------------------------------------------------">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  AWS AutoScaling Group modify processes to "$asg_modify_action_name" Summary Report">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  Script Version: "$script_version"">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  Date: "$date_file"">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  AWS Account: "$this_aws_account"  "$this_aws_account_alias"">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  Autoscaling Group Process modification: "$asg_modify_action_name" ">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  Autoscaling Group name matched: "$autoscaling_group_name" ">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  Number of AutoScaling Groups modified to "$asg_modify_action_name": "$count_asg_modify_process" ">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
if [[ "$logging" == "y" ]] ;
    then
        echo "  AWS AutoScaling Group modify processes to "$asg_modify_action_name" job log file: ">>"$this_summary_report_full_path"
        echo "  "$write_path"/ ">>"$this_summary_report_full_path"        
        echo "  "$this_log_file" ">>"$this_summary_report_full_path"
        echo "">>"$this_summary_report_full_path"
        echo "">>"$this_summary_report_full_path"
fi
echo "  ------------------------------------------------------------------------------------------">>"$this_summary_report_full_path"
count_error_lines="$(cat "$this_log_file_errors_full_path" | wc -l)"
if (( "$count_error_lines" > 2 ))
    then
        echo "">>"$this_summary_report_full_path"
        echo "">>"$this_summary_report_full_path"
        # add the errors to the report
        feed_write_log="$(cat "$this_log_file_errors_full_path">>"$this_summary_report_full_path" 2>&1)"
        fnWriteLog ${LINENO} "$feed_write_log"
        echo "">>"$this_summary_report_full_path"
        echo "">>"$this_summary_report_full_path"
        echo "  ------------------------------------------------------------------------------------------">>"$this_summary_report_full_path"
fi
echo "">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
#
# write the process status of the modified ASGs to the report
#
echo "  Modified Autoscaling Group processes status:">>"$this_summary_report_full_path"
echo "  -----------------------------------------------------------------------">>"$this_summary_report_full_path"
#
# initialize the ASG process status file
echo "">"$this_path"/asg-process-status.json 
#
# initialize the report counter
counter_report=0
# load the ASG process status file
for asg_name_process_status in $(echo $list_asg_modify_process) ; 
    do 
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "----------------------- loop head: create report asg name status -----------------------  "
        fnWriteLog ${LINENO} ""
        #
        # display the header    
        fnHeader
        # display the task progress bar
        fnProgressBarTaskDisplay "$counter_report" "$count_asg_modify_process"
        #
        fnWriteLog ${LINENO} level_0 ""
        fnWriteLog ${LINENO} level_0 "Creating job summary report file "
        fnWriteLog ${LINENO} level_0 ""
        #
        # pull the ASG process status from AWS
        echo "--------------------------------------------------------------------------------------------------------------">>"$this_path"/asg-process-status.json
        aws autoscaling describe-auto-scaling-groups --auto-scaling-group-name "$asg_name_process_status" --profile "$cli_profile" \
        | jq '.AutoScalingGroups[] | {AutoScalingGroupName}, {SuspendedProcesses}' \
        | tr -d ',"[]{} ' | grep -v '^$' | grep -v "SuspensionReason" | sed 's/ProcessName:/ - /' >>"$this_path"/asg-process-status.json   
        #
        # check for command / pipeline error(s)
        if ["$?" -ne 0 ]
            then
                #
                # set the command/pipeline error line number
                error_line_pipeline="$((${LINENO}-7))"
                #
                # call the command / pipeline error function
                fnErrorPipeline
                #
        #
        fi
        #
        echo "--------------------------------------------------------------------------------------------------------------">>"$this_path"/asg-process-status.json
        #
        # increment the modify counter
        fnCounterIncrementReport
        #
        fnWriteLog ${LINENO} ""
        fnWriteLog ${LINENO} "----------------------- loop tail: create report asg name status -----------------------  "
        fnWriteLog ${LINENO} ""
        #
    done
    #
    fnWriteLog ${LINENO} ""
    fnWriteLog ${LINENO} "----------------------- done: create report asg name status -----------------------  "
    fnWriteLog ${LINENO} ""
    #
#
# display the header    
fnHeader
# display the task progress bar
fnProgressBarTaskDisplay "$counter_report" "$count_asg_modify_process"
#
# add leading 5 characters to match report margin
cat "$this_path"/asg-process-status.json  | sed -e 's/^/     /'>>"$this_summary_report_full_path"
#
#
echo "">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "  ------------------------------------------------------------------------------------------">>"$this_summary_report_full_path"
echo "  ------------------------------------------------------------------------------------------">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
echo "">>"$this_summary_report_full_path"
#
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "Summary report complete. "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "Report is located here: "
fnWriteLog ${LINENO} level_0 "$this_summary_report_full_path"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------- end: print summary report for each LC name ---------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
##########################################################################
#
#
# delete the work files 
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "---------------------------------------- begin: delete work files ----------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnHeader
fnDeleteWorkFiles
fnWriteLog ${LINENO} ""  
#
fnWriteLog ${LINENO} "increment the task counter"
fnCounterIncrementTask
#
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------- end: delete work files -----------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} "----------------------------------------------------------------------------------------------------------"
fnWriteLog ${LINENO} ""
fnWriteLog ${LINENO} ""
#
##########################################################################
#
#
# done 
#
fnHeader
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "                            Job Complete "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 " Summary report location: "
fnWriteLog ${LINENO} level_0 " "$write_path"/ "
fnWriteLog ${LINENO} level_0 " "$this_summary_report" "
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
if [[ "$logging" = "y" ]] ;
    then
        fnWriteLog ${LINENO} level_0 " Log location: "
        fnWriteLog ${LINENO} level_0 " "$write_path"/ "
        fnWriteLog ${LINENO} level_0 " "$this_log_file" "
        fnWriteLog ${LINENO} level_0 ""
fi 
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 "----------------------------------------------------------------------"
fnWriteLog ${LINENO} level_0 ""
fnWriteLog ${LINENO} level_0 ""
if (( "$count_error_lines" > 2 ))
    then
    fnWriteLog ${LINENO} level_0 ""
    feed_write_log="$(cat "$this_log_file_errors_full_path" 2>&1)" 
    fnWriteLog ${LINENO} level_0 "$feed_write_log"
    fnWriteLog ${LINENO} level_0 ""
    fnWriteLog ${LINENO} level_0 "----------------------------------------------------------------------"
    fnWriteLog ${LINENO} level_0 ""
fi
#
##########################################################################
#
#
# write the stop timestamp to the log 
#
#
date_now="$(date +"%Y-%m-%d-%H%M%S")"
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "run end timestamp: "$date_now" " 
fnWriteLog ${LINENO} "" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "-------------------------------------------------------------------------------------------" 
fnWriteLog ${LINENO} "" 
#
##########################################################################
#
#
# write the log file 
#
if [[ ("$logging" = "y") || ("$logging" = "z") ]] 
    then 
        # append the temp log onto the log file
        fnWriteLogTempFile
        # write the log variable to the log file
        fnWriteLogFile
    else 
        # delete the temp log file
        rm -f "$this_log_temp_file_full_path"        
fi
#
# exit with success 
exit 0
#
#
# ------------------ end script ----------------------
