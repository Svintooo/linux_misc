# Custom Prompt (using Starship)
# # Setup extra hooks for Starship
# #https://unix.stackexchange.com/questions/361988/how-to-detect-if-a-command-was-provided-to-the-shell-prompt
# #https://stackoverflow.com/questions/27384748/detect-empty-command/27473009#27473009
___trap_command(){
  if [[ "$___trap_command_ready" == true ]]; then
    export ___trap_command_ready=false
    "${starship_trap_command_user_func-:}"
  else
    "${starship_trap_nocommand_user_func-:}"
  fi
  export ___trapDbg_ready=true
}
___trapDbg() {
  local c="$BASH_COMMAND"
  [[ "$c" == "starship_precmd" ]] && export ___trapDbg_ready=false  # Compatibility with Starship
  [[ "$c" == "___trap_command" ]] && export ___trapDbg_ready=false
  if [[ "$___trapDbg_ready" == true ]]; then
    export ___trapDbg_ready=false
    export ___trap_command_ready=true
  fi
}
starship_precmd_user_func=___trap_command
___trap_command_ready=true  # Make sure the first row is visible on shell start
trap '___trapDbg' DEBUG

# # Initiate Starship
eval "$(starship init bash)"
bash_prompt_command() { true; }  # Overwrite existing one in /home/zankhug/.afs/1/pprofiles/project_bashrc

# # Swap between different Starship configurations
___swap_starship_conf() {
  ( cd ~/.config/; ln -sf starship.toml.remove_1st_line starship.toml )
}
___swap_back_starship_conf() {
  ( cd ~/.config/; ln -sf starship.toml.original starship.toml )
}
starship_trap_command_user_func=___swap_back_starship_conf
starship_trap_nocommand_user_func=___swap_starship_conf
