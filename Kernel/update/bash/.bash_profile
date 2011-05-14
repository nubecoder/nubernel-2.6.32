PATH="/sbin:/system/bin:/system/xbin:/system/sbin"

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# Enable color
CLICOLOR=1

# set history file path
HISTFILE="/mnt/sdcard/.bash_history"

# don't put duplicate lines in the history. See bash(1) for more options
# ... or force ignoredups and ignorespace
HISTCONTROL=ignoredups:ignorespace

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=131072
HISTFILESIZE=1048576

# Prompt color codes
txtblk='\e[0;30m' # Black - Regular
txtred='\e[0;31m' # Red
txtgrn='\e[0;32m' # Green
txtylw='\e[0;33m' # Yellow
txtblu='\e[0;34m' # Blue
txtpur='\e[0;35m' # Purple
txtcyn='\e[0;36m' # Cyan
txtwht='\e[0;37m' # White
bldblk='\e[1;30m' # Black - Bold
bldred='\e[1;31m' # Red
bldgrn='\e[1;32m' # Green
bldylw='\e[1;33m' # Yellow
bldblu='\e[1;34m' # Blue
bldpur='\e[1;35m' # Purple
bldcyn='\e[1;36m' # Cyan
bldwht='\e[1;37m' # White
unkblk='\e[4;30m' # Black - Underline
undred='\e[4;31m' # Red
undgrn='\e[4;32m' # Green
undylw='\e[4;33m' # Yellow
undblu='\e[4;34m' # Blue
undpur='\e[4;35m' # Purple
undcyn='\e[4;36m' # Cyan
undwht='\e[4;37m' # White
bakblk='\e[40m'   # Black - Background
bakred='\e[41m'   # Red
badgrn='\e[42m'   # Green
bakylw='\e[43m'   # Yellow
bakblu='\e[44m'   # Blue
bakpur='\e[45m'   # Purple
bakcyn='\e[46m'   # Cyan
bakwht='\e[47m'   # White
txtrst='\e[0m'    # Text Reset

PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME%%.*}:${PWD/#$HOME/~}\007"'
# Red prompt when in a root shell
if [ ${EUID} -eq 0 ]; then
	#PS1="\[$txtred\][\t \u@\h\[\e[m\] \[$txtblu\]\W\[\e[m\]\[$txtred\]]# \[\e[m\]"
	PS1="\[$txtred\][\t\[\e[m\] \[$txtblu\]\W\[\e[m\]\[$txtred\]]# \[\e[m\]"
else
	#PS1="\[$txtgrn\][\t \u@\h\[\e[m\] \[$txtblu\]\W\[\e[m\]\[$txtgrn\]]$ \[\e[m\]"
	PS1="\[$txtgrn\][\t\[\e[m\] \[$txtblu\]\W\[\e[m\]\[$txtgrn\]]$ \[\e[m\]"
fi
PS2='> '
PS4='+ '

# aliases
#
# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
# NOTE:: not sure this would work in android
#alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'
#
# Set up a ton of aliases to cover toolbox with the nice busybox equivalents of its commands
#
alias cat='busybox cat'
alias chmod='busybox chmod'
alias chown='busybox chown'
alias cp='busybox cp'
alias df='busybox df'
alias insmod='busybox insmod'
alias l='busybox ls -CF'
alias la='busybox ls -A'
alias ll='busybox ls -AlF'
alias ln='busybox ln'
alias ls='busybox ls'
alias lsmod='busybox lsmod'
alias mkdir='busybox mkdir'
alias more='busybox more'
alias mount='busybox mount'
alias mv='busybox mv'
alias rm='busybox rm'
alias rmdir='busybox rmdir'
alias rmmod='busybox rmmod'
alias umount='busybox umount'
alias vi='busybox vi'
