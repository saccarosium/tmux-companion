LN := ln -vsf
MKDIR := mkdir -pv
CHMOD := chmod +x
DIR := $(HOME)/.local/bin

install:
	$(MKDIR) $(DIR)
	$(LN) $(PWD)/tm $(DIR)/tm
	$(CHMOD) $(DIR)/tm

update:
	git pull --rebase origin
