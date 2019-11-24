.PHONY: test UnitTest/makefile deploylocalLibs clean
space:=
space+=

MAKEFILE_DIR:=$(subst $(space),\$(space),$(shell dirname $(subst $(space),\$(space),$(realpath $(lastword $(MAKEFILE_LIST))))))

deploylocalLibs:
	@cp $(MAKEFILE_DIR)/FHEM/*.pm /opt/fhem/FHEM/

	
UnitTest/makefile: 
	@mkdir -p $(dir $@)
	@test -f $@ || wget -O $@ https://raw.githubusercontent.com/fhem/UnitTest/master/makefile
test: UnitTest/makefile deploylocalLibs
	${MAKE} -f $< fhem_kill setupEnv test PERL_OPTS="-MDevel::Cover"

clean:  UnitTest/makefile	
	${MAKE} -f $< clean
	@rm UnitTest/makefile || true

