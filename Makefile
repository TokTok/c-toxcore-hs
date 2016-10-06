CPPFLAGS	:= -I$(shell ghc --print-libdir)/include -Isrc
GHC_VERSION	:= $(shell ghc --numeric-version)
SOURCES		:= $(shell find src -name "*.hs")
SYMBOLS		:= $(shell egrep -Ro 'foreign export ccall \w+' src | awk '{print $$4}')

ifneq ($(shell uname),Darwin)
LDFLAGS		:= -ldl
DYLDFLAGS	:= -optl -Wl,--version-script,libtoxcore-hs.ver
#DYLDFLAGS	+= -optl -Wl,-z,defs
endif

ifneq ($(wildcard ../.cabal-sandbox/*-packages.conf.d),)
PACKAGE_DB	:= -package-db $(wildcard ../.cabal-sandbox/*-packages.conf.d)
endif

check: test-program
	./$<

test-program: test/test-program.c libtoxcore-hs.so Makefile
	$(CC) $< $(CPPFLAGS) $(CFLAGS) $(LDFLAGS) -o $@

libtoxcore-hs.so: src/hsbracket.c Makefile libtoxcore-hs.ver $(SOURCES) Makefile
	ghc $(PACKAGE_DB) 		\
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
