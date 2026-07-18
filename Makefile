.PHONY: check harness build preview package clean

check:
	./tools/check.sh

harness:
	/usr/bin/python3 harness/run.py

build:
	./tools/build.sh

preview: build
	./tools/preview.sh

package: check build
	./tools/package.sh

clean:
	rm -rf dist
