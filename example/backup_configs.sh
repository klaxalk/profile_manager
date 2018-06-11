# - make the script run in bash/zsh while having its dotfile sourced
# - this is important when there are variables exported, which might
#   be used by this script
# - however for this to work, the variable definition in .bashrc
#   should be above the "interactivity" condition, zsh is fine.
PNAME=$( ps -p "$$" -o comm= )
SNAME=$( echo "$SHELL" | grep -Eo '[^/]+/?$' )
if [ "$PNAME" != "$SNAME" ]; then
  exec "$SHELL" "$0" "$@"
  exit "$?"
else
  source ~/."$SNAME"rc
fi

../profileManager.sh backup example_file_list.txt
