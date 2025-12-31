export GALLIUM_DRIVER=d3d12

for i in "/mnt/wslg/runtime-dir/"*; do
  [ "$XDG_RUNTIME_DIR" = "$HOME" ] && XDG_RUNTIME_DIR="/var/run/user/$UID"
  if [ ! -L "$XDG_RUNTIME_DIR$(basename "$i")" ]; then
    [ -d "$XDG_RUNTIME_DIR$(basename "$i")" ] && rm -r "$XDG_RUNTIME_DIR$(basename "$i")"
    ln -s "$i" "$XDG_RUNTIME_DIR$(basename "$i")"
  fi
done
