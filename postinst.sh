#!/bin/sh

if [ $UID -ne 0 ]; then
	sudo $0 $USER
	
	# Disable Screensaver for this user
	defaults -currentHost write com.apple.screensaver idleTime 0
	
	exit
elif [ "x$1" != "x" ]; then
	USER=$1
fi

OSX_VERS=$(sw_vers -productVersion | awk -F "." '{print $2}')
PlistBuddy="/usr/libexec/PlistBuddy"

target_ds_node="/private/var/db/dslocal/nodes/Default"
# Override the default behavior of sshd on the target volume to be not disabled
if [ "$OSX_VERS" -ge 10 ]; then
    OVERRIDES_PLIST="/private/var/db/com.apple.xpc.launchd/disabled.plist"
    $PlistBuddy -c 'Delete :com.openssh.sshd' "$OVERRIDES_PLIST"
    $PlistBuddy -c 'Add :com.openssh.sshd bool False' "$OVERRIDES_PLIST"
else
    OVERRIDES_PLIST="/private/var/db/launchd.db/com.apple.launchd/overrides.plist"
    $PlistBuddy -c 'Delete :com.openssh.sshd' "$OVERRIDES_PLIST"
    $PlistBuddy -c 'Add :com.openssh.sshd:Disabled bool False' "$OVERRIDES_PLIST"
fi

# Add user to sudoers
cp "/etc/sudoers" "/etc/sudoers.orig"
echo "$USER ALL=(ALL) NOPASSWD: ALL" >> "/etc/sudoers"

# Add user to admin group memberships (even though GID 80 is enough for most things)
USER_GUID=$($PlistBuddy -c 'Print :generateduid:0' "$target_ds_node/users/$USER.plist")
USER_UID=$($PlistBuddy -c 'Print :uid:0' "$target_ds_node/users/$USER.plist")
$PlistBuddy -c 'Add :groupmembers: string '"$USER_GUID" "$target_ds_node/groups/admin.plist"

# Add user to SSH SACL group membership
ssh_group="${target_ds_node}/groups/com.apple.access_ssh.plist"
$PlistBuddy -c 'Add :groupmembers array' "${ssh_group}"
$PlistBuddy -c 'Add :groupmembers:0 string '"$USER_GUID"'' "${ssh_group}"
$PlistBuddy -c 'Add :users array' "${ssh_group}"
$PlistBuddy -c 'Add :users:0 string '$USER'' "${ssh_group}"

# Enable Remote Desktop and configure user with full privileges
echo "enabled" > "/private/etc/RemoteManagement.launchd"
$PlistBuddy -c 'Add :naprivs array' "$target_ds_node/users/$USER.plist"
$PlistBuddy -c 'Add :naprivs:0 string -1073741569' "$target_ds_node/users/$USER.plist"

# csrutil disable

# Suppress annoying iCloud welcome on a GUI login
$PlistBuddy -c 'Add :DidSeeCloudSetup bool true' "/Users/$USER/Library/Preferences/com.apple.SetupAssistant.plist"
$PlistBuddy -c 'Add :LastSeenCloudProductVersion string 10.'"$OSX_VERS" "/Users/$USER/Library/Preferences/com.apple.SetupAssistant.plist"

# Disable Diagnostics submissions prompt if 10.10
# http://macops.ca/diagnostics-prompt-yosemite
if [ "$OSX_VERS" -ge 10 ]; then
    # Apple's defaults
    SUBMIT_TO_APPLE=YES
    SUBMIT_TO_APP_DEVELOPERS=NO

    CRASHREPORTER_SUPPORT="/Library/Application Support/CrashReporter"
    CRASHREPORTER_DIAG_PLIST="${CRASHREPORTER_SUPPORT}/DiagnosticMessagesHistory.plist"
    if [ ! -d "${CRASHREPORTER_SUPPORT}" ]; then
        mkdir "${CRASHREPORTER_SUPPORT}"
        chmod 775 "${CRASHREPORTER_SUPPORT}"
        chown root:admin "${CRASHREPORTER_SUPPORT}"
    fi
    for key in AutoSubmit AutoSubmitVersion ThirdPartyDataSubmit ThirdPartyDataSubmitVersion; do
        $PlistBuddy -c "Delete :$key" "${CRASHREPORTER_DIAG_PLIST}" 2> /dev/null
    done
    $PlistBuddy -c "Add :AutoSubmit bool ${SUBMIT_TO_APPLE}" "${CRASHREPORTER_DIAG_PLIST}"
    $PlistBuddy -c "Add :AutoSubmitVersion integer 4" "${CRASHREPORTER_DIAG_PLIST}"
    $PlistBuddy -c "Add :ThirdPartyDataSubmit bool ${SUBMIT_TO_APP_DEVELOPERS}" "${CRASHREPORTER_DIAG_PLIST}"
    $PlistBuddy -c "Add :ThirdPartyDataSubmitVersion integer 4" "${CRASHREPORTER_DIAG_PLIST}"
fi

# Disable loginwindow screensaver to save CPU cycles
$PlistBuddy -c 'Add :loginWindowIdleTime integer 0' "/Library/Preferences/com.apple.screensaver.plist"

# Disable the welcome screen
touch "/private/var/db/.AppleSetupDone"

# Disable Time Machine
tmutil disablelocal

# Download and install system updates
#softwareupdate -i -a

# Disable Spotlight
launchctl remove -w /System/Library/LaunchDaemons/com.apple.metadata.mds.plist

# Disable Watchdog
launchctl remove -w /System/Library/LaunchDaemons/com.apple.watchdogd.plist
