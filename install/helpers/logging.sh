log_step() {
  local message="$1"
  gum style --foreground 6 "ℹ  $message"
}

log_success() {
  local message="$1"
  gum style --foreground 2 "✅ $message"
}

log_info() {
  local message="$1"
  gum style --foreground 8 "  → $message"
}

run_logged() {
  local script="$1"
  shift  # Remove first argument, leaving any additional args
  local script_name=$(basename "$script")
  export CURRENT_SCRIPT="$script"

  echo
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] \033[36mRUNNING:\033[0m $script_name $*"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  source "$script" "$@"
  local exit_code=$?

  if [ $exit_code -eq 0 ]; then
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] \033[32mSUCCESS:\033[0m Completed: $script_name"
    echo
    unset CURRENT_SCRIPT
  else
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] \033[31mERROR:\033[0m Failed: $script_name (exit code: $exit_code)"
    echo -e "\033[31mERROR: Failed: $script_name\033[0m"
  fi

  return $exit_code
}