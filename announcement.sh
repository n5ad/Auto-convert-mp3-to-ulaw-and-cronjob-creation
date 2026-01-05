#!/bin/bash

# this script was created by James Carnathan N5AD
# to better utilize scripts created by Freddie Macguire KD5FMU
echo "=== AllStar MP3 → u-law Sound Import ==="


TMP_DIR="/tmp"

CONVERT_SCRIPT="/etc/asterisk/local/audio_convert.sh"

PLAY_SCRIPT="/etc/asterisk/local/playaudio.sh"

SOUNDS_DIR="/usr/local/share/asterisk/sounds"


# Ask for MP3 filename

read -rp "Enter MP3 filename (located in /tmp): " MP3_NAME


SRC_MP3="$TMP_DIR/$MP3_NAME"


# Validate MP3 file

if [[ ! -f "$SRC_MP3" ]]; then

    echo "ERROR: File does not exist: $SRC_MP3"

    exit 1

fi


# Validate extension

if [[ "${MP3_NAME##*.}" != "mp3" ]]; then

    echo "ERROR: File must be an .mp3"

    exit 1

fi


# Validate converter script

if [[ ! -x "$CONVERT_SCRIPT" ]]; then

    echo "ERROR: Converter script not found or not executable:"

    echo "  $CONVERT_SCRIPT"

    exit 1

fi

if [[ ! -x "$PLAY_SCRIPT" ]]; then
	echo "ERROR: playaudio.sh not executable"
	exit 1
fi


echo "Running audio conversion script..."

"$CONVERT_SCRIPT" "$SRC_MP3"


# Build expected UL filename

BASE_NAME="${MP3_NAME%.mp3}"

UL_FILE="$TMP_DIR/$BASE_NAME.ul"


# Verify UL file was created

if [[ ! -f "$UL_FILE" ]]; then

    echo "ERROR: Conversion failed — UL file not found:"

    echo "  $UL_FILE"

    exit 1

fi


# Copy to Asterisk sounds directory

echo "Copying $BASE_NAME.ul to Asterisk sounds directory..."

cp "$UL_FILE" "$SOUNDS_DIR/" || exit 1


# Ensure correct permissions

chmod 644 "$SOUNDS_DIR/$BASE_NAME.ul"

chown root:root "$SOUNDS_DIR/$BASE_NAME.ul"


echo "SUCCESS!"

echo "Sound installed at:"

echo "  $SOUNDS_DIR/$BASE_NAME.ul"

echo

echo "=== Schedule Playback (cron) ==="

echo "Use * or ranges like 8-21 as needed"


read -rp "Minute (0-59): " CRON_MIN

read -rp "Hour (0-23): " CRON_HOUR

read -rp "Day of Month (1-31): " CRON_DOM

read -rp "Month (1-12): " CRON_MONTH

read -rp "Day of Week (0-7, Sun=0 or 7): " CRON_DOW

# ask for a description or comment about cronjob

read -rp "enter a short description for this announcement (optional): "  ANNOUNCE_DESC

PLAY_TARGET="$SOUNDS_DIR/$BASE_NAME"

# Cron comment line (optional)
if [[ -n "$ANNOUNCE_DESC" ]]; then
	COMMENT_LINE="# Announcement: $ANNOUNCE_DESC"
else
	COMMENT_LINE=""
fi


CRON_LINE="$CRON_MIN $CRON_HOUR $CRON_DOM $CRON_MONTH $CRON_DOW $PLAY_SCRIPT $PLAY_TARGET"


echo

echo "Installing cron entry:"

echo "$CRON_LINE"


(

    crontab -l 2>/dev/null
    [[ -n "$COMMENT_LINE" ]] && echo "$COMMENT_LINE"
    echo "$CRON_LINE"

) | crontab -


echo

echo "SUCCESS!"

echo "Announcement scheduled with description"
[[ -n "$ANNOUNCE_DESC" ]] && echo "  $ANNOUNCE_DESC"
echo "Cron Command:"
echo "  $CRON_LINE"

