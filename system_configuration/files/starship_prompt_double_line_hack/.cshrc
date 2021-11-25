### Custom prompt (using Starship)
# Tested with tcsh, not csh
eval `starship init tcsh`
alias precmd 'echo -n $_ | hexdump > /tmp/__zankhug__ ; if ( -e /tmp/__zankhug_hotstart__ ) mv /tmp/__zankhug_hotstart__ /tmp/__zankhug__ ; if ( -z /tmp/__zankhug__ ) ln -sf starship.toml.remove_1st_line ~/.config/starship.toml ; if ( -s /tmp/__zankhug__ ) ln -sf starship.toml.original ~/.config/starship.toml ; rm -f /tmp/__zankhug__' ";$STARSHIP_PRECMD";
echo RandomString > /tmp/__zankhug_hotstart__ # Make sure the first row is visible on shell start
