.PHONY: release qvm clean clean_assets clean_gamecode clean_output distclean

COMPILE_PLATFORM=$(shell uname|sed -e s/_.*//|tr '[:upper:]' '[:lower:]')

COMPILE_ARCH=$(shell uname -m | sed -e s/i.86/i386/)

ifeq ($(COMPILE_PLATFORM),sunos)
  # Solaris uname and GNU uname differ
  COMPILE_ARCH=$(shell uname -p | sed -e s/i.86/i386/)
endif
ifeq ($(COMPILE_PLATFORM),darwin)
  # Apple does some things a little differently...
  COMPILE_ARCH=$(shell uname -p | sed -e s/i.86/i386/)
endif

ifeq ($(COMPILE_PLATFORM),mingw32)
  ifeq ($(COMPILE_ARCH),i386)
    COMPILE_ARCH=x86
  endif
endif

GAMECODE_DIR := ratoa_gamecode
GAMECODE_QVM_DIR := $(GAMECODE_DIR)/build/release-$(COMPILE_PLATFORM)-$(COMPILE_ARCH)/baseq3/vm
QVM_BUILD_DIR := build/linux-qvm
ASSETS_DIR := ratoa_assets

GAMECODE_OPTS := WITH_MULTITOURNAMENT=0

OUTPUT_DIR := build
PK3_DIR := $(OUTPUT_DIR)/pk3

RATMOD_PK3 = zz-tmod.pk3

TIMESTAMP = @$(shell cd $(GAMECODE_DIR) && git show -s --format=%ct 2>/dev/null || echo 0)

release: qvm $(OUTPUT_DIR) 
	rm -rf $(PK3_DIR)
	mkdir $(PK3_DIR)
	cp -r $(ASSETS_DIR)/assets/* $(PK3_DIR)/
	# cp $(GAMECODE_DIR)/README.md $(PK3_DIR)/
	mkdir $(PK3_DIR)/vm
	cp $(QVM_BUILD_DIR)/vm/*.qvm $(PK3_DIR)/vm/ 2>/dev/null || cp $(GAMECODE_QVM_DIR)/*.qvm $(PK3_DIR)/vm/ 2>/dev/null || true
	#cd $(PK3_DIR) && zip -r ../$(RATMOD_PK3) -- .
	cd $(PK3_DIR) && $(CURDIR)/caca_deterministic_zip.sh \
		$(TIMESTAMP) ../$(RATMOD_PK3) .

qvm:
	$(MAKE) -C $(QVM_BUILD_DIR) || \
	($(MAKE) -C $(GAMECODE_DIR) $(GAMECODE_OPTS) \
		BUILD_GAME_SO=0 BUILD_GAME_QVM=1 && \
	 cp $(GAMECODE_QVM_DIR)/*.qvm $(QVM_BUILD_DIR)/vm/ 2>/dev/null || true)

$(OUTPUT_DIR):
	mkdir -p $(OUTPUT_DIR)

clean_assets:
	$(MAKE) -C $(ASSETS_DIR) clean

clean_gamecode:
	$(MAKE) -C $(GAMECODE_DIR) clean
	$(MAKE) -C $(QVM_BUILD_DIR) clean 2>/dev/null || true

clean_output:
	rm -rf $(OUTPUT_DIR)

clean: clean_assets clean_gamecode clean_output

distclean: clean_assets clean_output
	$(MAKE) -C $(GAMECODE_DIR) distclean
