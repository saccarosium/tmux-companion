LN := ln -vsf
MKDIR := mkdir -pv
CHMOD := chmod +x
DIR := $(HOME)/.local/bin

install:
	$(MKDIR) $(DIR)
	$(LN) $(PWD)/bin/tm $(DIR)/tm
	$(LN) $(PWD)/bin/tm-preset $(DIR)/tm-preset
	$(CHMOD) $(DIR)/tm
	$(CHMOD) $(DIR)/tm-preset

update:
	git pull --rebase origin
