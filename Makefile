SHELL := /bin/bash 

.PHONY: test

rsync:
	rsync -urltv --delete --exclude-from='rsyncignore.txt' -e ssh . snail:~/work/cl-builder

getwave:
	scp snail:~/work/cl-builder/test/vsim.wlf ./wave

viewwave: getwave
	(cd ./wave; vsim -view vsim.wlf & > /dev/null 2>&1 &)

wave: viewwave

test:
	cd test; source ~/local/h/h.sh; runSVUnit -s questa -r "-do config/log_wave.do" | h "Error|FAILED" PASSED "Warning|RUNNING"

testsetup:
	cd test; vlib alt_lib; vlog -work alt_lib -l compile.log -f /homes/obrienfr/intel/spmat_afu/hw/test/config/altera_base.f
