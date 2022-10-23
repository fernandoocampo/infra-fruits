build: clone build-lambda

clone:
	rm -rf lambda-repo
	mkdir lambda-repo
	git clone git@github.com:fernandoocampo/gofunction.git ./lambda-repo

build-lambda:
	cd lambda-repo
	make -C ./lambda-repo all

clean:
	rm -rf lambda-repo