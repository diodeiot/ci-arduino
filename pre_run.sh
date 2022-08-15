#!/bin/bash

###################################################################
# Checks before run.
#
# Author: Diode IoT Inc. <info@diodeiot.com>
# Maintainer: Kadir Sevil <kadir.sevil@diodeiot.com>
#
# Copyright (c) 2021-2022 Diode Iot Inc. All rights reserved.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
###################################################################

set -e

echo "Setting up the script..."

# Check if .clang-format file exists in the root directory
if [ -f ".clang-format" ]; then
  echo ".clang-format found"
else
  echo ".clang-format not found!" >&2
  exit 1
fi
