# Makefile

CC     = gcc
CFLAGS = -std=c11 -Wall -Wextra -Wpedantic -g

# Modules de la bibliotheque (sans main)
MODULES = matrice.o matrice_alloc.o matrice_io.o matrice_calcul.o

# Les tests ont besoin de -DMAT_TEST_ALLOC (simulation d'echec d'allocation) :
# leurs fichiers objets sont donc compiles a part, avec le suffixe .t.o
TFLAGS = $(CFLAGS) -DMAT_TEST_ALLOC

PROGS = demo_matrices test_ex1 test_ex2 test_ex3

all: $(PROGS)

# Programme de demonstration (sans -DMAT_TEST_ALLOC)
demo_matrices: main.o $(MODULES)
	$(CC) $^ -o $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Programmes de test (avec -DMAT_TEST_ALLOC)
test_ex1: test_ex1.t.o matrice.t.o matrice_alloc.t.o
	$(CC) $^ -o $@

test_ex2: test_ex2.t.o matrice.t.o matrice_alloc.t.o matrice_io.t.o
	$(CC) $^ -o $@

test_ex3: test_ex3.t.o matrice.t.o matrice_alloc.t.o matrice_calcul.t.o
	$(CC) $^ -o $@

%.t.o: %.c
	$(CC) $(TFLAGS) -c $< -o $@

# Dependances vers les en-tetes
main.o: main.c matrice.h matrice_alloc.h matrice_io.h matrice_calcul.h
matrice.o matrice.t.o: matrice.c matrice.h
matrice_alloc.o matrice_alloc.t.o: matrice_alloc.c matrice_alloc.h matrice.h
matrice_io.o matrice_io.t.o: matrice_io.c matrice_io.h matrice_alloc.h matrice.h
matrice_calcul.o matrice_calcul.t.o: matrice_calcul.c matrice_calcul.h matrice_alloc.h matrice.h
test_ex1.t.o: test_ex1.c matrice.h matrice_alloc.h
test_ex2.t.o: test_ex2.c matrice.h matrice_alloc.h matrice_io.h
test_ex3.t.o: test_ex3.c matrice.h matrice_alloc.h matrice_calcul.h

# Lancer les tests
test: test_ex1 test_ex2 test_ex3
	./test_ex1 | tail -2
	./test_ex2 | tail -2
	./test_ex3 | tail -2

clean:
	rm -f *.o $(PROGS) test_ex2_sortie.txt R.txt R2.txt

.PHONY: all test clean
