SHELL := /bin/bash 

.PHONY: test

default: test

rsync:
	rsync -urltv --delete --exclude-from='rsyncignore.txt' -e ssh . snail:~/work/cl-builder

getwave:
	scp snail:~/work/cl-builder/test/vsim.wlf ./.wave

viewwave: getwave
	(cd ./wave; vsim -view vsim.wlf & > /dev/null 2>&1 &)

wave: 
	vsim -view test/vsim.wlf

test:
	cd test; source ~/local/h/h.sh; runSVUnit -s questa -r "-L alt_lib -voptargs=+acc -do config/log_wave.do" -f config/test_sources.f  | h "Error[s]?|FAILED" PASSED "Warning[s]?|RUNNING"

testsetup:
	cd test; vlib alt_lib; vlog -work alt_lib -l compile.log -f ./config/altera_base.f
