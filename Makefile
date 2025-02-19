STUID = ysyx_22040000
STUNAME = 吴墨林

# DO NOT modify the following code!!!

TRACER = tracer-ysyx
GITFLAGS = -q --author='$(TRACER) <tracer@ysyx.org>' --no-verify --allow-empty

YSYX_HOME = $(NEMU_HOME)/..
WORK_BRANCH = $(shell git rev-parse --abbrev-ref HEAD)
WORK_INDEX = $(YSYX_HOME)/.git/index.$(WORK_BRANCH)
TRACER_BRANCH = $(TRACER)

LOCK_DIR = $(YSYX_HOME)/.git/

# prototype: git_soft_checkout(branch)
define git_soft_checkout
	git checkout --detach -q && git reset --soft $(1) -q -- && git checkout $(1) -q --
endef

# prototype: git_commit(msg)
define git_commit
	-@flock $(LOCK_DIR) $(MAKE) -C $(YSYX_HOME) .git_commit MSG='$(1)'
	-@sync $(LOCK_DIR)
endef

.git_commit:
	-@while (test -e .git/index.lock); do sleep 0.1; done;               `# wait for other git instances`
	-@git branch $(TRACER_BRANCH) -q 2>/dev/null || true                 `# create tracer branch if not existent`
	-@cp -a .git/index $(WORK_INDEX)                                     `# backup git index`
	-@$(call git_soft_checkout, $(TRACER_BRANCH))                        `# switch to tracer branch`
	-@git add . -A --ignore-errors                                       `# add files to commit`
	-@(echo "> $(MSG)" && echo $(STUID) $(STUNAME) && uname -a && uptime `# generate commit msg`) \
	                | git commit -F - $(GITFLAGS)                        `# commit changes in tracer branch`
	-@$(call git_soft_checkout, $(WORK_BRANCH))                          `# switch to work branch`
	-@mv $(WORK_INDEX) .git/index                                        `# restore git index`

.clean_index:
	rm -f $(WORK_INDEX)

_default:
	@echo "Please run 'make' under subprojects."

.PHONY: .git_commit .clean_index _default

# My own code below

# SystemC configuration
SYSTEMC_INCLUDE = /home/willlin/workspace/second/gitpkg/systemc-3.0.0/include/
SYSTEMC_LIBDIR = /home/willlin/workspace/second/gitpkg/systemc-3.0.0/lib-linux64/

EXPORT_SC = export SYSTEMC_INCLUDE=$(SYSTEMC_INCLUDE) &&\
		export SYSTEMC_LIBDIR=$(SYSTEMC_LIBDIR) && \

LINK = export LD_LIBRARY_PATH=$(SYSTEMC_LIBDIR) && \


# Verilator configuration
VERILATOR = verilator
VERILATOR_FLAGS_TRACE = --trace-fst
VERILATOR_FLAGS_CC = --cc --exe -O3 -Wall
VERILATOR_FLAGS_INIT = --x-assign fast --x-initial fast
VERILATOR_FLAGS = $(VERILATOR_FLAGS_CC) $(VERILATOR_FLAGS_TRACE) $(VERILATOR_FLAGS_INIT)
VERILATOR_CFLAGS =  -CFLAGS -I$(NVBOARD_INCLUDE) -CFLAGS -I$(SDL2_INCLUDE) -CFLAGS -DTOP_NAME="\"V$(TOP_NAME)\""
VERILATOR_LDFLAGS_NVB =  -LDFLAGS -lSDL2 -LDFLAGS -lSDL2_image -LDFLAGS -lSDL2_ttf

# Directory configuration
DIR_VSRC = npc/vsrc/
DIR_CSRC = npc/csrc/
DIR_NXDC = npc/constr/
DIR_BUILD = build/
DIR_OUTPUT = build/obj_dir/

# Cpp wrapper
WRAPPER_TEMPLATE = main.template 
WRAPPER_CC = main# default name
WRAPPER = $(WRAPPER_CC)
CSRCS = $(shell find $(abspath ./npc/csrc) -name "*.c" -or -name "*.cc" -or -name "*.cpp")

# Verilog sourcefile
VSRCS = $(shell find $(abspath ./npc/vsrc) -name "*.v")
TOP_NAME = top# default name

# Gtkwave
GTKWAVE = gtkwave
WAVE = wave#default name
VCD = .vcd
FST = .fst
WAVE_SUFFIX = $(FST)

# nvboard
NVBOARD_HOME = /home/willlin/workspace/nvboard/
NVBOARD_LIB = $(NVBOARD_HOME)build/nvboard.a
SDL2_INCLUDE = /usr/include/SDL2/
NVBOARD_INCLUDE = $(NVBOARD_HOME)usr/include/
EXPORT_NVB = export NVBOARD_HOME=$(NVBOARD_HOME) &&\

include $(NVBOARD_HOME)/scripts/nvboard.mk

debug:
	@echo CSRCS:$(CSRCS)
	@echo VSRCS:$(VSRCS)

exec: compile
	./$(DIR_OUTPUT)V$(TOP_NAME)


compile: cpp
	make -j -C $(DIR_OUTPUT) -f V$(TOP_NAME).mk V$(TOP_NAME) 

cpp: build
	$(VERILATOR) $(VERILATOR_FLAGS) $(CSRCS) $(VSRCS) $(NVBOARD_LIB) \
	--top-module $(TOP_NAME) -Mdir $(DIR_OUTPUT) \
	$(VERILATOR_CFLAGS) \
	$(VERILATOR_LDFLAGS_NVB)

env: build
	$(VERILATOR) $(VERILATOR_FLAGS) $(VSRCS) --top-module $(TOP_NAME) -Mdir $(DIR_OUTPUT)

build:
	mkdir -p build

# Generate a simple testbench template for cpp wrapper
template:
	cp $(DIR_CSRC)$(WRAPPER_TEMPLATE) $(DIR_CSRC)$(WRAPPER_CC).cpp

# Open waveform if exists
wave: 
	$(GTKWAVE) $(DIR_OUTPUT)$(WAVE)$(WAVE_SUFFIX)

# Generate auto-bind for nvboard
bind:
	rm -rf $(DIR_NXDC)$(TOP_NAME).nxdc
	$(DIR_NXDC)nxdc_gen.py --top_name $(TOP_NAME)
	python $(NVBOARD_HOME)/scripts/auto_pin_bind.py $(DIR_NXDC)$(TOP_NAME).nxdc $(DIR_CSRC)auto_bind.cpp


clean:
	rm -f $(DIR_CSRC)auto_bind.cpp
	rm -f $(DIR_NXDC)$(TOP_NAME).nxdc
	rm -rf $(DIR_BUILD)

