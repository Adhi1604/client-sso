echo ":bust_in_silhouette: Enter the Linux username to delete (e.g., refex):"
read DEL_USER
if id "$DEL_USER" &>/dev/null; then
  echo ":mag_right: Checking for running processes by '$DEL_USER'..."
  USER_PIDS=$(pgrep -u "$DEL_USER")
  if [ -n "$USER_PIDS" ]; then
    echo ":warning: User '$DEL_USER' is running processes. Killing them..."
    sudo kill -9 $USER_PIDS
    sleep 1
  fi
  echo ":wastebasket: Deleting user '$DEL_USER' and their home directory..."
  sudo deluser --remove-home "$DEL_USER" || {
    echo ":x: Failed to delete user '$DEL_USER'."
    exit 1
  }
  echo ":white_check_mark: User '$DEL_USER' deleted."
else
  echo ":information_source: User '$DEL_USER' does not exist. Skipping."
fi