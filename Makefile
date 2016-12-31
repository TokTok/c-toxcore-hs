ifneq ($(wildcard ../stack.yaml),)
GHC		:= stack --stack-yaml $(dir $(CURDIR))/stack.yaml ghc --
else
GHC		:= ghc
endif

CPPFLAGS	:= -I$(shell $(GHC) --print-libdir)/include -Isrc
CFLAGS		:= -g3
GHC_VERSION	:= $(shell $(GHC) --numeric-version)
SOURCES		:= $(shell find src -name "*.hs")
SYMBOLS		:= $(shell egrep -Ro 'foreign export ccall \w+' src | awk '{print $$4}')

ifneq ($(shell uname),Darwin)
LDFLAGS		:= -ldl -pthread
DYLDFLAGS	:= -optl -Wl,--version-script,libtoxcore-hs.ver
#DYLDFLAGS	+= -optl -Wl,-z,defs
endif

ifneq ($(shell which valgrind),)
ifneq ($(shell which gdb),)
RUN_DEBUGGER	= valgrind ./$< || gdb -batch -ex "run" -ex "bt" ./$<
endif
endif

ifeq ($(RUN_DEBUGGER),)
RUN_DEBUGGER	= false
endif

check: test-program
	./$< || $(RUN_DEBUGGER)

test-program: test/test-program.c libtoxcore-hs.so Makefile
	$(CC) $< $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) -o $@

libtoxcore-hs.so: src/hsbracket.c Makefile libtoxcore-hs.ver $(SOURCES) Makefile
	$(GHC) $(PACKAGE_DB) 		\
		-O2 -shared -fPIC	\
		-dynamic		\
		$(DYLDFLAGS)		\
		-o libtoxcore-hs.so	\
		src/hsbracket.c		\
		$(filter %.hs,$^)	\
		-lHSrts-ghc$(GHC_VERSION)

libtoxcore-hs.ver: $(SOURCES) Makefile
	@echo "Generating $@"
	@echo '{'		>  $@
	@echo '  global:'	>> $@
	@for n in $(SYMBOLS); do	\
		echo "    $$n;"	>> $@;	\
	done
	@echo '  local: *;'	>> $@
	@echo '};'		>> $@
