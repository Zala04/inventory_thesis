#!/bin/bash
set -e  # Exit on error
Rscript DataGen.R
Rscript TileForecasting.R
