CC = gcc
CFLAGS = -I./src -I./obj -std=gnu99 -g

LEX=flex

YACC=bison -y
YFLAGS=-v -d -b obj/y
GRAMMAR=parser.y

obj/mcc: obj/lex.yy.o obj/y.tab.o obj/tree.o obj/driver.o obj/strtab.o | obj
	$(CC) $(CFLAGS) -o $@ $^ -lfl

obj/y.tab.h obj/y.tab.c: src/$(GRAMMAR) | obj
	$(YACC) $(YFLAGS) $<

obj/y.tab.o: obj/y.tab.c | obj
	$(CC) $(CFLAGS) -c $< -o $@

obj/lex.yy.o: obj/lex.yy.c | obj
	$(CC) $(CFLAGS) -c $< -o $@

obj/lex.yy.c: src/scanner.l obj/y.tab.h | obj
	$(LEX) -o $@ $<

obj/tree.o: src/tree.c src/tree.h obj/y.tab.h | obj
	$(CC) $(CFLAGS) -c $< -o $@

obj/driver.o: src/driver.c src/tree.h obj/y.tab.h | obj
	$(CC) $(CFLAGS) -c $< -o $@

obj/strtab.o: src/strtab.c src/strtab.h obj/y.tab.h | obj
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY: clean test objdir testAll

obj:
	@mkdir -p obj

clean:
	@rm -rf obj
	@rm -f lex.yy.* *.o *~ scanner

test: obj/mcc
	@python ./test/testParser.py

.PHONY: testAll

testAll: obj/mcc
	@for file in test/*.mC; do \
		echo "Testing $$file:"; \
		./obj/mcc < "$$file" > "$$file.out" 2>&1 || echo "Error occurred"; \
		echo "Output:"; \
		cat "$$file.out"; \
		echo "Exit status: $$?"; \
		echo "----------------------------------------"; \
	done
	@rm -f test/*.out

.PHONY: testAll2

testAll2: obj/mcc
	@echo "Running all tests and writing output to testOutput.txt"
	@echo "" > testOutput.txt
	@for file in test/*.mC; do \
		echo "Testing $$file:" >> testOutput.txt; \
		./obj/mcc < "$$file" > "$$file.out" 2>&1 || echo "Error occurred" >> testOutput.txt; \
		echo "Output:" >> testOutput.txt; \
		cat "$$file.out" >> testOutput.txt; \
		echo "Exit status: $$?" >> testOutput.txt; \
		echo "----------------------------------------" >> testOutput.txt; \
	done
	@rm -f test/*.out
	@echo "Test results have been written to testOutput.txt"
