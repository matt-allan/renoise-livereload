XRNX := com.matta.devtools.xrnx
SOURCES := $(wildcard *.lua) 

$(XRNX): $(SOURCES) LICENSE.md manifest.xml
	zip -vr $@ $^

.PHONY: clean
clean:
	rm $(XRNX)