#!/bin/bash

sdkVersion="7.0.302"
runtimeVersion="7.0.5"

# Find SDK paths
sdkPaths=$(find /usr/local/share/dotnet/ -type d -name "$sdkVersion")

# Find runtime paths
runtimePaths=$(find /usr/local/share/dotnet/ -type d -name "$runtimeVersion")

# Delete SDK paths
for path in $sdkPaths; do
    sudo rm -rf "$path"
done

# Delete runtime paths
for path in $runtimePaths; do
    sudo rm -rf "$path"
done

