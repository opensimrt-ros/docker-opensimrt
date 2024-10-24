#!/usr/bin/env bash

log_info()
{
	echo -e "\e[97m [INFO] [$EPOCHREALTIME]: $@ \e[0m"

}
log_warn()
{
	echo -e "\e[33m [WARN] [$EPOCHREALTIME]: $@ \e[0m"

}
log_debug()
{
	echo -e "\e[32m [DEBUG] [$EPOCHREALTIME]: $@ \e[0m"

}


