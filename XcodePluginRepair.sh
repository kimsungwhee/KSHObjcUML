#!/bin/bash

UUID=$(defaults read /Applications/Xcode.app/Contents/Info DVTPlugInCompatibilityUUID)

echo Xcode DVTPlugInCompatibilityUUID is $UUID


for PluginList in ~/Library/Application\ Support/Developer/Shared/Xcode/Plug-ins/*

do

defaults write "$PluginList"/Contents/Info DVTPlugInCompatibilityUUIDs -array-add $UUID

echo write DVTPlugInCompatibilityUUID to $PluginList succeed!

done