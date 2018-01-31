###############################################################################
# File:                  Makefile
# Process Name:          CPCPerl5Lib
# Functionality:         Create HTML Documentation
# Author:                Adam Allgood
# Date Makefile created: 2013-02-22
###############################################################################

# --- Declare variables ---

DOCDIR    = ./doc
HTMDIR    = ./doc/html

# --- Rules ---

.PHONY: doc

# --- doc ---

doc:
	/usr/bin/perl MakeDocHTML.pl

