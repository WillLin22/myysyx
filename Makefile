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

EXPORT = export SYSTEMC_INCLUDE=$(SYSTEMC_INCLUDE) &&\
		export SYSTEMC_LIBDIR=$(SYSTEMC_LIBDIR) && \

LINK = export LD_LIBRARY_PATH=$(SYSTEMC_LIBDIR) && \


# Verilator configuration
VERILATOR = verilator
VERILATOR_FLAGS_TRACE = --trace-fst
VERILATOR_FLAGS_CC = --cc --exe --Wall 
VERILATOR_FLAGS = $(VERILATOR_FLAGS_CC) $(VERILATOR_FLAGS_TRACE)

# Directory configuration
DIR_VSRC = npc/vsrc/
DIR_CSRC = npc/csrc/
DIR_OUTPUT = obj_dir/

# Cpp wrapper
WRAPPER_TEMPLATE = main.template 
WRAPPER_CC = main# default name
WRAPPER = $(WRAPPER_CC)

# Verilog sourcefile
FILENAME = top# default name

# Gtkwave
GTKWAVE = gtkwave
WAVE = wave#default name
VCD = .vcd
FST = .fst
WAVE_SUFFIX = $(FST)


exec: compile
	./$(DIR_OUTPUT)V$(FILENAME)

compile: cpp
	make -j -C $(DIR_OUTPUT) -f V$(FILENAME).mk V$(FILENAME)

cpp:
	$(VERILATOR) $(VERILATOR_FLAGS) $(DIR_CSRC)$(WRAPPER).cpp $(DIR_VSRC)$(FILENAME).v

env:
	$(VERILATOR) $(VERILATOR_FLAGS) $(DIR_VSRC)$(FILENAME).v

template:
	cp $(DIR_CSRC)$(WRAPPER_TEMPLATE) $(DIR_CSRC)$(WRAPPER_CC).cpp

wave: 
	$(GTKWAVE) $(DIR_OUTPUT)$(WAVE)$(WAVE_SUFFIX)

clean:
	rm -r $(DIR_OUTPUT)
