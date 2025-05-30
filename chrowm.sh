#!/bin/bash

# ========= CHECK INPUT =========
if [ -z "$1" ]; then
  echo "❌ Usage: $0 \"App Name With Spaces\""
  exit 1
fi

# ========= PARSE INPUT =========
APP_NAME="$*"
read -r FIRST LAST <<<"$(echo "$APP_NAME" | awk '{print $1, $NF}')"
word_count=$(echo "$APP_NAME" | wc -w)

if [ "$word_count" -eq 1 ]; then
  INITIALS=$(echo "$APP_NAME" | cut -c1 | tr '[:lower:]' '[:upper:]')
else
  read -r FIRST LAST <<<"$(echo "$APP_NAME" | awk '{print $1, $NF}')"
  FIRST_INITIAL=$(echo "$FIRST" | cut -c1)
  LAST_INITIAL=$(echo "$LAST" | cut -c1)
  INITIALS=$(echo "$FIRST_INITIAL$LAST_INITIAL" | tr '[:lower:]' '[:upper:]')
fi
SAFE_NAME=$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

CHROME_PROFILE_DIR="$HOME/.config/google-chrome/chrowm/$SAFE_NAME"
ICON_PATH="$HOME/.local/share/applications/$SAFE_NAME.svg"
DESKTOP_FILE="$HOME/.local/share/applications/$SAFE_NAME.desktop"

# ========= GENERATE BRIGHT BACKGROUND COLOR =========
hash=$(echo -n "$APP_NAME" | sha1sum | awk '{print $1}')
R_HEX=${hash:0:2}
G_HEX=${hash:2:2}
B_HEX=${hash:4:2}

R=$R_HEX
G=$G_HEX
B=$B_HEX
BG_COLOR="#$R$G$B"

# Convert hex to decimal for brightness calculation
hex_to_dec() {
  echo $((16#$1))
}

R_DEC=$(hex_to_dec "$R_HEX")
G_DEC=$(hex_to_dec "$G_HEX")
B_DEC=$(hex_to_dec "$B_HEX")

# Calculate perceived brightness (0-255 scale)
brightness=$(echo "0.299 * $R_DEC + 0.587 * $G_DEC + 0.114 * $B_DEC" | bc)

# Decide font color based on brightness threshold
if (( $(echo "$brightness > 186" | bc -l) )); then
  FONT_COLOR="#000000"  # black text for bright background
else
  FONT_COLOR="#FFFFFF"  # white text for dark background
fi

# ========= CREATE CUSTOM ICON WITH PROVIDED SVG AND COLORS =========
cat > "$ICON_PATH" <<EOF
<svg xmlns="http://www.w3.org/2000/svg" enable-background="new 0 0 24 24" viewBox="0 0 24 24" width="256" height="256" id="chrome">
  <circle fill="$BG_COLOR" fill-opacity="1.0" cx="12.001" cy="12.001" r="4.046"></circle>
  <path fill="$BG_COLOR" fill-opacity="1.0" d="M10.138 23.851l3.082-6.039c-2.787.522-5.478-1.006-6.75-3.508l-4.514-8.88C.722 7.311 0 9.576 0 12 0 18.001 4.394 22.971 10.138 23.851zM17.996 22.39c5.197-3 7.302-9.291 5.197-14.705l-6.759.348c1.835 2.144 1.863 5.236.319 7.607l-5.425 8.342C13.578 24.103 15.896 23.61 17.996 22.39zM6.364 10.138c.924-2.652 3.601-4.234 6.412-4.069l9.934.522c-1.017-2.013-2.614-3.765-4.714-4.984C16.095.508 14.004-.014 11.957 0 8.425.015 4.97 1.592 2.667 4.457l3.697 5.681H6.364z"></path>
  <text x="50%" y="50%" text-anchor="middle" font-family="sans-serif" font-size="16" fill="$FONT_COLOR" dy=".3em" font-weight="bold">$INITIALS</text>
</svg>
EOF

# ========= CREATE .desktop FILE =========
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$APP_NAME
StartupWMClass=$SAFE_NAME
Exec=google-chrome-stable --class=$SAFE_NAME --user-data-dir="$CHROME_PROFILE_DIR"
Icon=$ICON_PATH
Terminal=false
Categories=Network;WebBrowser;
EOF

chmod +x "$DESKTOP_FILE"

# ========= DONE =========
echo "✅ Created launcher: $DESKTOP_FILE"
echo "🖼️  Icon: $ICON_PATH (Initials: $INITIALS, Background: $BG_COLOR, Font color: $FONT_COLOR)"
