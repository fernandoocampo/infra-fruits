build: clone build-lambda

clone:
	rm -rf gofunction
	mkdir gofunction
	git clone git@github.com:fernandoocampo/gofunction.git ./gofunction

build-lambda:
	make -C ./gofunction all

clean:
	rm -rf gofunction