#!/bin/bash

# This script can be used as a postflight to help install packages that require a logged in user
# Just create a dmg with the package(s) to be installed and place it in the Resources directory within a Payloadless package that uses this as its postflight
# This script will mount the dmg, and if no user is logged in at install time, it will create a temporary user and login so the install succeeds

RESOURCES_DIR=`dirname "$0"`

# mount the dmg
echo "mounting dmg..."
DMG_MOUNT=`hdiutil attach -nobrowse "${RESOURCES_DIR}"/*.dmg | grep Apple_HFS | sed 's,.*/Volumes,/Volumes,g' | head -1`

if ! who | grep -q " console "; then
  echo "No user logged in. Creating user..."
  DID_CREATE_USER="YES"

  WINDOWSERVERPASSWD=`uuidgen`
  # create our install user
  dscl . -create /Users/windowserver_install
  dscl . -create /Users/windowserver_install RealName "windowserver_install"
  dscl . -create /Users/windowserver_install UniqueID 8888
  dscl . -create /Users/windowserver_install PrimaryGroupID 20
  dscl . -create /Users/windowserver_install UserShell /bin/bash
  dscl . -create /Users/windowserver_install NFSHomeDirectory /Users/windowserver_install

  # hiding password is not important since this is just a temporary account
  dscl . -passwd /Users/windowserver_install $WINDOWSERVERPASSWD

  echo "Setting up automatic login..."
  # setup the install account for autologin using kcpassword
  "${RESOURCES_DIR}"/kcpassword_create.pl windowserver_install $WINDOWSERVERPASSWD

  echo "Logging in..."
  # login by restarting loginwindow
  killall loginwindow

  # wait for login
  while ! who | grep -q " console "
  do
    echo "Waiting for windowserver_install login..."
    sleep 1
  done

  echo "Removing kcpassword..."
  # once logged in, secure remove /etc/kcpassword
  srm /etc/kcpassword

  # open iHook as needed to prevent User control and show progress
  echo "Starting iHook.app script..."
  "${RESOURCES_DIR}"/iHook.app/Contents/MacOS/iHook"

else
  echo "User is already logged in, so we have a window server"
fi

echo "Installing all pkgs in dmg mount..."
# install all packages in our dmg
for package in "${DMG_MOUNT}"/*pkg
do
  echo "Installing ${package}..."
  installer -pkg "${package}" -target / -verboseR
done

# detach the dmg
echo "Unmounting dmg..."
hdiutil detach "${DMG_MOUNT}"

# if we logged in our own user, clean up and log it out
if [ ! "${DID_CREATE_USER+xxx}" = "xxx" ]; then

  # logout by killing loginwindow
  echo "Logging out temporary user..."
  killall loginwindow

  # clean up our window server account
  echo "Deleting temporary user..."
  dscl . -delete /Users/windowserver_install

  echo "Removing windowserver_install home..."
  rm -Rf /Users/windowserver_install

fi

echo "Install complete."
exit 0

