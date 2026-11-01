# TD — Stockage de matrices en C

- **Membres** : Tarek BEN AMOR (@tbenamor), Nour AISSA (@naissa123), Sana BEN CHAABANE (@Sana5651)
- **Groupe de TD** : 2
- **Date de remise** : 2 novembre 2026

## Table des matières
1. [Introduction](#1-introduction)
2. [Conception](#2-conception)
3. [Réalisation](#3-réalisation)
4. [Vérifications mémoire](#4-vérifications-mémoire)
5. [Démonstration](#5-démonstration)
6. [Bilan et difficultés](#6-bilan-et-difficultés)

## 1. Introduction

## 2. Conception

### Schéma des modules

La bibliothèque est formée de quatre modules ; `main.c` (le programme de démonstration) et les programmes de test les utilisent sans contenir aucune logique de matrices eux-mêmes. Une flèche signifie « appelle des fonctions de » :

```text
                       main.c (demo_matrices)
           charger / sauvegarder (static), main
           |              |                |
           v              v                v
     matrice_io     matrice_calcul    matrice_alloc
     mat_lire       mat_additionner   mat_detruire (nettoyage)
     mat_ecrire     mat_multiplier
     mat_afficher
           |              |
           +------+-------+
                  v
            matrice_alloc
            mat_allouer, mat_detruire
                  |
                  v
               matrice
     mat_est_valide, mat_message_erreur
```

- `matrice` contient ce qui est commun à tous : le type `Matrice`, les codes `MatErreur`, `mat_est_valide` (utilisée par `matrice_io` et `matrice_calcul` avant de toucher une matrice) et `mat_message_erreur` (utilisée par `main.c` pour afficher les erreurs).
- `matrice_alloc` est le seul module qui réserve et libère la mémoire des coefficients : `matrice_io` et `matrice_calcul` passent par `mat_allouer` et `mat_detruire`, sans jamais appeler `calloc` ni `free` directement.
- `matrice_calcul` n'utilise pas les fichiers : il n'inclut donc pas `matrice_io.h`.

### Graphe des inclusions

Une flèche `X → Y` signifie « X contient `#include "Y"` » :

```text
matrice_alloc.h   → matrice.h
matrice_io.h      → matrice.h, <stdio.h>
matrice_calcul.h  → matrice.h

matrice.c         → matrice.h
matrice_alloc.c   → matrice_alloc.h
matrice_io.c      → matrice_io.h, matrice_alloc.h
matrice_calcul.c  → matrice_calcul.h, matrice_alloc.h
main.c            → matrice.h, matrice_alloc.h, matrice_io.h, matrice_calcul.h
```

Le graphe ne contient aucun cycle. Chaque `.c` inclut son propre `.h`, ce qui permet au compilateur de vérifier que les définitions correspondent aux prototypes. `matrice_io.h` inclut `<stdio.h>` car ses prototypes utilisent le type `FILE`.

**Pourquoi le garde `#ifndef` est nécessaire.** `main.c` inclut `matrice.h` directement, mais aussi indirectement via `matrice_alloc.h`, `matrice_io.h` et `matrice_calcul.h` : sans protection, le type `Matrice` et l'énumération `MatErreur` seraient définis quatre fois, ce qui est une erreur de compilation. Chaque en-tête est donc entouré de :

```c
#ifndef MATRICE_H
#define MATRICE_H
/* ... contenu ... */
#endif
```

À la première inclusion, `MATRICE_H` n'est pas défini : le contenu est lu et la macro est définie. Aux inclusions suivantes dans le même fichier, `MATRICE_H` existe déjà et tout le contenu est ignoré.

### Règles de propriété de la mémoire

Toutes les fonctions respectent les règles R1 à R7 du sujet. En résumé :

| Règle | Contenu | Où on l'applique |
|---|---|---|
| R1 | toute variable `Matrice` est initialisée à `MATRICE_VIDE` | `Matrice a = MATRICE_VIDE, b = ..., r = ...;` dans `main` |
| R2 | une fonction qui réussit transfère la propriété du résultat à l'appelant, qui doit appeler `mat_detruire` | fin de `mat_allouer`, `mat_lire`, `mat_additionner`, `mat_multiplier` |
| R3 | une fonction qui échoue laisse `*res` à `MATRICE_VIDE` et a tout libéré | `*res = MATRICE_VIDE;` au début de chaque fonction, `mat_detruire(&tmp)` ou libération des lignes avant chaque `return` d'erreur |
| R4 | une matrice d'entrée n'est jamais modifiée ni libérée | paramètres `const Matrice *` |
| R5 | `*res` est un paramètre de sortie, distinct des entrées | `verifier_parametres` refuse `res == a` ou `res == b` |
| R6 | `mat_detruire` remet la matrice à vide, donc un second appel est sans effet | `*m = MATRICE_VIDE;` à la fin de `mat_detruire` |
| R7 | un fichier est fermé par le code qui l'a ouvert | `fopen`/`fclose` uniquement dans `charger` et `sauvegarder` (`main.c`) |

**Qui alloue, qui utilise, qui libère.** Dans `demo_matrices`, `a` et `b` sont allouées par `mat_lire`, `r` par `mat_additionner` ou `mat_multiplier`, et toutes les trois sont libérées par `main`, en un seul point de sortie (`nettoyage:`). Grâce à R1 et R6, ce nettoyage n'a pas besoin de savoir quelles matrices ont été créées : `mat_detruire` est sans effet sur une matrice vide.

**Ce que vaut une matrice après un échec.** Toujours `MATRICE_VIDE` : l'appelant ne reçoit jamais une matrice à moitié construite ou à moitié remplie. Pour cela, `mat_allouer` ne remplit `*res` qu'après la dernière allocation réussie, et `mat_lire` lit dans une matrice locale `tmp` qu'elle ne transfère à `*res` qu'à la fin.

### Justification des choix

**Fonctions `static`.** Une fonction interne à un module est déclarée `static` : elle n'est visible que dans son fichier, n'apparaît pas dans le `.h`, et ne peut pas entrer en conflit avec une fonction de même nom ailleurs. C'est le cas de :

| Fonction | Fichier | Rôle |
|---|---|---|
| `mat_calloc` | `matrice_alloc.c` | `calloc` instrumenté, pour simuler un manque de mémoire dans les tests |
| `lire_entier` | `matrice_io.c` | lit un entier en détectant les données invalides |
| `verifier_parametres` | `matrice_calcul.c` | contrôles communs à l'addition et à la multiplication |
| `tient_dans_int` | `matrice_calcul.c` | dit si un résultat `long long` tient dans un `int` |
| `charger`, `sauvegarder` | `main.c` | ouverture, lecture/écriture et fermeture d'un fichier |

**Échec partiel de l'allocation.** Une matrice n × p demande 1 + n allocations (le tableau des pointeurs, puis chaque ligne). Si l'allocation de la ligne `i` échoue, `mat_allouer` libère les lignes `i-1` à `0`, puis le tableau `coef`, dans cet ordre car les adresses des lignes sont rangées dans `coef`. Les programmes de test simulent un échec à chaque allocation possible (grâce à `mat_calloc` et à l'option `-DMAT_TEST_ALLOC`), et valgrind confirme qu'aucune zone n'est perdue.

**Détection du dépassement.** Le dépassement d'un `int` signé est un comportement indéfini en C : il faut le détecter avant qu'il ne se produise. Les calculs sont donc faits en `long long` (la somme ou le produit de deux `int` y tient toujours), puis `tient_dans_int` vérifie que le résultat est entre `INT_MIN` et `INT_MAX`, sinon on renvoie `MAT_ERR_DEPASSEMENT`. Pour le produit, la somme de p produits pourrait dépasser un `long long` : chaque addition est donc vérifiée avant d'être faite (`s > LLONG_MAX - p` ou `s < LLONG_MIN - p`).

**Gestion d'erreurs uniforme.** Toute fonction qui peut échouer renvoie un code `MatErreur` (`MAT_OK` en cas de succès) et n'affiche rien ; le résultat passe par un paramètre de sortie. C'est `main.c` qui affiche les messages, sur `stderr`, grâce à `mat_message_erreur`.

### Compilation

Le `Makefile` compile chaque `.c` séparément en fichier objet, puis fait l'édition de liens. Les programmes de test sont compilés avec `-DMAT_TEST_ALLOC` (simulation d'échec d'allocation) et pas `demo_matrices` : chaque module est donc compilé deux fois, en `module.o` pour la démonstration et en `module.t.o` pour les tests.

```text
make          # construit demo_matrices, test_ex1, test_ex2 et test_ex3
make test     # lance les trois tests et affiche leur bilan
make clean    # supprime les fichiers objets et les exécutables
```

Équivalent à la main, pour `demo_matrices` :

```text
gcc -std=c11 -Wall -Wextra -Wpedantic -g -c matrice.c
gcc -std=c11 -Wall -Wextra -Wpedantic -g -c matrice_alloc.c
gcc -std=c11 -Wall -Wextra -Wpedantic -g -c matrice_io.c
gcc -std=c11 -Wall -Wextra -Wpedantic -g -c matrice_calcul.c
gcc -std=c11 -Wall -Wextra -Wpedantic -g -c main.c
gcc main.o matrice.o matrice_alloc.o matrice_io.o matrice_calcul.o -o demo_matrices
```

et pour un test, par exemple :

```text
gcc -std=c11 -Wall -Wextra -Wpedantic -g -DMAT_TEST_ALLOC \
    test_ex1.c matrice.c matrice_alloc.c -o test_ex1
```

## 3. Réalisation

### Exercice 1 — Allocation et destruction

#### Code écrit

**1.a — Compléter les messages d'erreur** (`mat_message_erreur`) : deux cas ajoutés au `switch`, sur le modèle des autres, pour que ces codes ne tombent plus dans « erreur inconnue ».

```c
    case MAT_ERR_DIMENSIONS:  return "dimensions incompatibles";
    case MAT_ERR_DEPASSEMENT: return "dépassement de capacité (résultat hors de l'intervalle des int)";
```

**1.b — Écrire `mat_est_valide`** : les quatre conditions sont combinées par `&&`. L'ordre compte : si `m` vaut `NULL`, l'évaluation s'arrête avant de lire `(*m).coef`, ce qui évite un plantage. La notation `(*m).coef` est équivalente à `m->coef` (les parenthèses sont nécessaires car `.` est prioritaire sur `*`).

```c
    return m != NULL
        && (*m).coef != NULL
        && (*m).nb_lignes >= 1 && (*m).nb_lignes <= MAT_DIM_MAX
        && (*m).nb_colonnes >= 1 && (*m).nb_colonnes <= MAT_DIM_MAX;
```

**1.c — Refuser les dimensions invalides** (`mat_allouer`) : `*res` a déjà été mis à `MATRICE_VIDE` juste avant, et rien n'est encore alloué, donc on peut sortir directement.

```c
    if (nb_lignes < 1 || nb_lignes > MAT_DIM_MAX
        || nb_colonnes < 1 || nb_colonnes > MAT_DIM_MAX)
        return MAT_ERR_ARGUMENT;
```

**1.d — Réserver chaque ligne** : chaque ligne est allouée avec `mat_calloc` (coefficients mis à 0). En cas d'échec à la ligne `i`, on rend les lignes `i-1` à `0` déjà obtenues, puis le tableau `coef`, dans cet ordre car les adresses des lignes sont rangées dans `coef`.

```c
    for (int i = 0; i < nb_lignes; i++) {
        coef[i] = mat_calloc((size_t)nb_colonnes, sizeof *coef[i]);
        if (coef[i] == NULL) {
            /* échec : rendre ce qui a déjà été obtenu */
            for (int k = i - 1; k >= 0; k--)
                free(coef[k]);
            free(coef);
            return MAT_ERR_ALLOCATION;
        }
    }
```

**1.e — Remplir le résultat** : `*res` n'est rempli qu'une fois toutes les allocations réussies, pour que l'appelant ne reçoive jamais une matrice à moitié construite. La propriété de la mémoire lui est alors transférée (règle R2).

```c
    (*res).coef = coef;
    (*res).nb_lignes = nb_lignes;
    (*res).nb_colonnes = nb_colonnes;
    return MAT_OK;
```

**1.f — Écrire `mat_detruire`** : on libère les lignes, puis le tableau qui contient leurs adresses. La ligne fournie `*m = MATRICE_VIDE;` remet ensuite `coef` à `NULL`, ce qui rend un second appel sans effet (règle R6).

```c
    if ((*m).coef != NULL) {
        for (int i = 0; i < (*m).nb_lignes; i++)
            free((*m).coef[i]);
        free((*m).coef);
    }
```

#### Questions de réflexion

**Q3.1** — Avec un `Matrice *`, la fonction peut modifier la variable de l'appelant et la remettre à `MATRICE_VIDE` après les `free`. Avec un passage par valeur, elle travaillerait sur une copie : la mémoire serait libérée, mais la variable de l'appelant garderait l'ancienne adresse dans `coef`. Un deuxième appel ferait alors un double `free`.

**Q3.2** — Il faut 1 + n `calloc` (le tableau de pointeurs + une ligne par ligne) et autant de `free`. Si la k-ième allocation échoue, on a déjà obtenu k − 1 zones, donc il faut k − 1 `free` (0 si c'est le tableau `coef` qui échoue).

**Q3.3** — Après le premier appel, `coef` vaut `NULL`, donc le deuxième appel ne libère rien. Par contre, avec `Matrice b = a;`, seul le pointeur est copié : `a` et `b` partagent les mêmes lignes. `mat_detruire(&a)` remet `a` à vide mais pas `b`, donc `mat_detruire(&b)` libère une deuxième fois la même mémoire.

**Q3.4** — Comme ça, `*res` est vide dans tous les cas d'erreur, même quand on sort tout de suite à cause de mauvaises dimensions (1.c). L'appelant ne reçoit jamais une matrice avec un contenu au hasard, et il peut toujours appeler `mat_detruire` sans risque.

#### Résultat du test

```text
=== Exercice 1 : matrice.c ===
[OK]    (1.a) message pour MAT_ERR_DIMENSIONS
[OK]    (1.a) message pour MAT_ERR_DEPASSEMENT
[OK]    (1.b) une matrice 1 x 2 est valide
[OK]    (1.b) NULL n'est pas valide
[OK]    (1.b) MATRICE_VIDE n'est pas valide
[OK]    (1.b) une matrice de 0 ligne n'est pas valide
=== Exercice 1 : matrice_alloc.c ===
[OK]    (1.c) mat_allouer refuse 0 ligne
[OK]    (1.c) mat_allouer refuse -2 colonnes
[OK]    (1.c) mat_allouer refuse une dimension > MAT_DIM_MAX
[OK]    (1.e) mat_allouer(&m, 3, 4) renvoie MAT_OK
[OK]    (1.e) m a 3 lignes et 4 colonnes
[OK]    (1.d) tous les coefficients valent 0
[OK]    (1.f) apres mat_detruire, m est vide
[OK]    (1.f) un second mat_detruire est sans danger
[OK]    (1.f) mat_detruire(NULL) ne plante pas
=== Exercice 1 : echecs d'allocation simules ===
[OK]    (1.d) chaque echec renvoie MAT_ERR_ALLOCATION et laisse *res vide

Bilan : 16 / 16 verifications reussies.
```

### Exercice 2 — Entrées-sorties

#### Code écrit

**2.a — Afficher les coefficients** (`mat_afficher`) : une double boucle parcourt la matrice ligne par ligne, affiche chaque coefficient sur 8 caractères, puis passe à la ligne.

```c
    for (int i = 0; i < m->nb_lignes; i++) {
        for (int j = 0; j < m->nb_colonnes; j++) {
            printf(" %8d", m->coef[i][j]);
        }
        putchar('\n');
    }
```

**2.b — Écrire les coefficients** (`mat_ecrire`) : le premier coefficient d'une ligne est écrit avec `"%d"` et les suivants avec `" %d"`, pour n'avoir aucun espace en fin de ligne. Chaque écriture est vérifiée.

```c
    for (int i = 0; i < m->nb_lignes; i++) {
        for (int j = 0; j < m->nb_colonnes; j++) {
            if (j == 0) {
                if(fprintf(f, "%d", m->coef[i][j]) < 0) {
                    return MAT_ERR_ECRITURE;
                }
            }
            else {
                if(fprintf(f, " %d", m->coef[i][j]) < 0) {
                    return MAT_ERR_ECRITURE;
                }
            }
        }
        if(fputc('\n',f) == EOF) { return MAT_ERR_ECRITURE; }
    }
```

**2.c — Vérifier les dimensions lues** (`mat_lire`) : des dimensions hors de 1 à `MAT_DIM_MAX` viennent du contenu du fichier, d'où `MAT_ERR_FORMAT`.

```c
    if (nb_lignes <= 0
    || nb_lignes > MAT_DIM_MAX
    || nb_colonnes <= 0
    || nb_colonnes > MAT_DIM_MAX ) { return MAT_ERR_FORMAT; }
```

**2.d — Réserver une matrice locale** : si `mat_allouer` échoue, elle a déjà tout libéré et `tmp` est vide, donc il n'y a rien à rendre.

```c
    Matrice tmp;
    err = mat_allouer(&tmp, nb_lignes, nb_colonnes);
    if (err != MAT_OK) return err;
```

**2.e — Lire les coefficients** : en cas d'erreur de lecture, on détruit `tmp` avant de renvoyer l'erreur.

```c
    for (int i = 0; i < nb_lignes; i++) {
        for (int j = 0; j < nb_colonnes; j++) {
            err = lire_entier(f, &tmp.coef[i][j]);
            if (err != MAT_OK) {
                mat_detruire(&tmp);
                return err;
            }
        }
    }
```

**2.f — Transférer le résultat** : `*res` n'est rempli qu'une fois toutes les lectures réussies.

```c
    *res = tmp;  return MAT_OK;
```

#### Questions de réflexion

**Q4.1** — Notre `mat_lire` remplit d'abord une matrice locale (un brouillon) et ne l'affecte à `*res` qu'une fois toutes les lectures réussies. Ainsi, si une lecture échoue, il suffit de détruire `tmp` et l'appelant reçoit une matrice vide. Comme ça, il ne reçoit jamais une matrice à moitié remplie qui a l'air valide. Par exemple, dans le fichier `2 2 / 1 2 3` du test "coefficient manquant", il manque un quatrième nombre. Sans `tmp`, `res` contiendrait `[1 2] [3 0]`, le 0 est inventé par `calloc`, c'est une matrice qui a l'air valide mais son contenu est faux. On aurait pu écrire directement dans `res` mais il suffit d'oublier un `mat_detruire` et l'appelant aura une matrice fausse. Avec `tmp` le même oubli provoque une fuite de mémoire que valgrind détecte mais `res` reste vide. 

**Q4.2** — Non. L'appel `fscanf(f, "%31s", mot)` dans `lire_entier` lit un mot en sautant tous les blancs. Pour `mat_lire`, le fichier n'est donc qu'une suite de nombres, et un fichier `2 2` suivi de `1 2 3 4` sur une seule ligne donne la même matrice que s'il était écrit sur deux lignes.

Ce n'est pas gênant : le nombre de lectures est fixé par les dimensions et les coefficients sont rangés dans l'ordre, donc seule la mise en page est ignorée. Le contenu reste vérifié strictement (coefficient manquant, mot non numérique ou entier trop grand donnent `MAT_ERR_FORMAT`), et le test « espaces et sauts de ligne en trop sont tolérés » passe.

Strict en écriture, parce que le fichier que nous écrivons sera lu par d'autres : `mat_ecrire` produit toujours le même format, que n'importe quel lecteur peut relire. Tolérant en lecture, parce que les fichiers lus peuvent venir de n'importe où. On accepte les petites différences de mise en page, car seuls les nombres comptent.

**Q4.3** — Comme `mat_lire` laisse le flux juste après le dernier coefficient, un second appel sur le même `f` lit la matrice suivante. Par exemple, avec ce fichier :

```text
2 2
1 2
3 4
2 2
5 6
7 8
```

```c
mat_lire(f, &a); /* lit 2 2 puis 1 2 3 4 : a = [1 2] [3 4] */
mat_lire(f, &b); /* repart après le 4, lit 2 2 puis 5 6 7 8 */
```

Le premier appel lit les dimensions `2 2` puis les 4 coefficients de `a`, et s'arrête juste après le `4`. Le second lit alors `2 2` comme dimensions de `b`, puis ses 4 coefficients. Les deux appels doivent se faire sur le même flux, sans le fermer entre les deux : c'est possible car `mat_lire` ne ferme jamais le flux qu'elle reçoit (règle R7).

**Q4.4** — `mat_ecrire` appelle `fflush` pour forcer la transmission des données au système d'exploitation avant de répondre `MAT_OK` : sinon, les données pourraient être encore en attente dans le tampon, et une erreur (disque plein) passerait inaperçue ou ne serait découverte qu'au `fclose`.

Cela ne dispense pas l’appelant de tester `fclose`, car la fermeture peut elle aussi échouer (disque réseau, espace insuffisant), et c’est pour cela que la fonction `sauvegarder` de `main.c` teste son résultat.

On peut le comparer à l'envoi d'un courrier : `fprintf` pose la lettre sur la pile du bureau (le tampon), `fflush` la remet au guichet de la poste (le système d'exploitation), et `fclose` clôture le dossier, moment où le guichet peut encore signaler un problème.

#### Résultat du test

```text
=== Exercice 2 : affichage (verification visuelle) ===
M (4 x 3) :
        1        2        3
        4        5        6
        7        8        9
       10       11       12
(2.a) Vous devez voir ci-dessus 4 lignes : 1 2 3 / 4 5 6 / 7 8 9 / 10 11 12
=== Exercice 2 : ecriture ===
[OK]    ouverture de test_ex2_sortie.txt en ecriture
[OK]    (2.b) mat_ecrire renvoie MAT_OK
[OK]    (2.b) le fichier contient exactement le format attendu
[OK]    (2.b) mat_ecrire refuse une matrice vide
=== Exercice 2 : relecture ===
[OK]    (2.f) mat_lire relit le fichier : MAT_OK
[OK]    (2.e) la matrice relue est identique
[OK]    (2.e) espaces et sauts de ligne en trop sont toleres
=== Exercice 2 : fichiers incorrects ===
[OK]    (2.c) fichier vide
[OK]    (2.c) dimension nulle
[OK]    (2.c) dimension negative
[OK]    (2.e) coefficient manquant
[OK]    (2.e) donnee non numerique
[OK]    (2.e) entier trop grand pour un int
=== Exercice 2 : echec d'allocation simule ===
[OK]    (2.d) mat_lire renvoie MAT_ERR_ALLOCATION proprement

Bilan : 14 / 14 verifications reussies.
```

### Exercice 3 — Calcul matriciel

#### Code écrit

**3.a — Contrôler les dimensions de l'addition** (`mat_additionner`) : deux matrices ne s'additionnent que si elles ont le même nombre de lignes **et** le même nombre de colonnes. On ne compare pas `nb_lignes * nb_colonnes` : une 2 × 3 et une 3 × 2 ont 6 coefficients chacune, mais ne s'additionnent pas.

```c
    if (a->nb_lignes != b->nb_lignes || a->nb_colonnes != b->nb_colonnes)
        return MAT_ERR_DIMENSIONS;
```

**3.b — Réserver le résultat** (`mat_additionner`) : `r` est déclarée vide (règle R1), puis allouée avec les dimensions de `a`. Si `mat_allouer` échoue, elle a déjà tout libéré et `r` est vide, donc il n'y a rien à rendre (R3).

```c
    Matrice r = MATRICE_VIDE;
    err = mat_allouer(&r, a->nb_lignes, a->nb_colonnes);
    if (err != MAT_OK)
        return err;
```

**3.c — Calculer chaque coefficient** (`mat_additionner`) : la somme est calculée en `long long`. Sans la conversion, `a->coef[i][j] + b->coef[i][j]` serait calculée en `int` et pourrait déborder avant le test `tient_dans_int`.

```c
    long long s = (long long)a->coef[i][j] + b->coef[i][j];
```

**3.d — Transférer le résultat** (`mat_additionner`) : `*res` n'est rempli qu'à la fin, quand tous les coefficients sont calculés. L'appelant devient propriétaire de la matrice et devra appeler `mat_detruire` (R2).

```c
    *res = r;
    return MAT_OK;
```

**3.e — Contrôler les dimensions du produit** (`mat_multiplier`) : le produit `a × b` n'existe que si le nombre de colonnes de `a` est égal au nombre de lignes de `b`.

```c
    if (a->nb_colonnes != b->nb_lignes)
        return MAT_ERR_DIMENSIONS;
```

**3.f — Réserver le résultat du produit** (`mat_multiplier`) : si `a` est n × p et `b` est p × q, le résultat est n × q.

```c
    Matrice r = MATRICE_VIDE;
    err = mat_allouer(&r, a->nb_lignes, b->nb_colonnes);
    if (err != MAT_OK)
        return err;
```

**3.g — La somme des produits** (`mat_multiplier`) : pour chaque case (i, j), la boucle sur `k` parcourt la ligne i de `a` et la colonne j de `b`. Avant chaque addition, on vérifie que `s + p` ne dépassera pas la capacité d'un `long long`. Comme `r` a déjà été allouée, on la détruit avant de renvoyer l'erreur, sinon elle serait perdue.

```c
    for (int k = 0; k < a->nb_colonnes; k++) {
        long long p = (long long)a->coef[i][k] * b->coef[k][j];
        if ((p > 0 && s > LLONG_MAX - p)
            || (p < 0 && s < LLONG_MIN - p)) {
            mat_detruire(&r);
            return MAT_ERR_DEPASSEMENT;
        }
        s += p;
    }
```

Exemple de vérification à la main : pour a = (1 2 3 / 4 5 6) et c = (7 8 / 9 10 / 11 12), c₁₁ = 1·7 + 2·9 + 3·11 = 58, ce que le test retrouve.

**3.h — Transférer le résultat** (`mat_multiplier`) : comme en 3.d, `*res = r; return MAT_OK;`.

#### Questions de réflexion

**Q5.1** — Non. Le `const` protège seulement la structure : `coef`, `nb_lignes` et
`nb_colonnes`. Par exemple, on ne peut pas écrire `a->nb_lignes = 0;`.
Mais `coef` est une adresse. Les nombres ne sont pas dans la structure. Ils ne sont pas `const`.
Donc on peut écrire `a->coef[0][0] = 7;`.
Pour l'interdire, il faut mettre les nombres en `const` : `const int *const *coef`.
Dans notre code, on ne change jamais `a`. On écrit seulement dans `r`.

**Q5.2** — `verifier_parametres` commence par `*res = MATRICE_VIDE;`.
Si `res` est `&a`, alors `a` devient vide avant le calcul.
On perd la mémoire de `a` : c'est une fuite. Et le calcul est faux.
Alors on refuse ce cas avec `MAT_ERR_ARGUMENT`.
Pour faire a = a + b, on met le résultat dans une autre matrice. Puis on détruit l'ancienne `a`.
Le test « resultat = entree refuse, a reste intacte » le vérifie : il affiche [OK].

**Q5.3** — Le résultat a n × q cases.
Pour chaque case, on fait p multiplications.
Total : n × p × q multiplications.
Pour 1000 × 1000 : 1000 × 1000 × 1000 = 1 milliard.

**Q5.4** — Si un `int` devient trop grand, le résultat est indéfini en C.
On ne sait pas ce qu'il vaut. Le test `s < a` peut ne pas marcher.
Il faut donc vérifier avant le calcul.
Nous calculons avec `long long`, qui est plus grand qu'un `int`.
Puis `tient_dans_int` vérifie que le résultat rentre dans un `int`.
Nous l'avons vérifié : le test « INT_MAX + 1 » renvoie bien `MAT_ERR_DEPASSEMENT` ([OK]).

#### Résultat du test

```text
=== Exercice 3 : addition ===
[OK]    (3.a) (2 x 3) + (3 x 2) : MAT_ERR_DIMENSIONS
[OK]    (3.d) (2 x 3) + (2 x 3) : MAT_OK
[OK]    (3.c) a + b est correct
[OK]    a et b n'ont pas ete modifiees
[OK]    (3.b) le resultat possede sa propre memoire
[OK]    (3.c) INT_MAX + 1 : MAT_ERR_DEPASSEMENT
=== Exercice 3 : multiplication ===
[OK]    (3.e) (2 x 3) x (2 x 3) : MAT_ERR_DIMENSIONS
[OK]    (3.h) (2 x 3) x (3 x 2) : MAT_OK
[OK]    (3.g) a x c = (58 64 / 139 154)
[OK]    (3.f) (3 x 2) x (2 x 3) donne une matrice 3 x 3
[OK]    a et c n'ont pas ete modifiees
[OK]    (3.g) 2 x 10^10 depasse INT_MAX : MAT_ERR_DEPASSEMENT
=== Exercice 3 : cas particuliers ===
[OK]    resultat = entree refuse, a reste intacte
[OK]    (3.f) echec d'allocation : MAT_ERR_ALLOCATION, r vide

Bilan : 14 / 14 verifications reussies.
```



### Exercice 4 — Démonstration complète

#### Code écrit

**4.a — Afficher A et B** : on n'arrive ici que si les deux chargements ont réussi (sinon le `goto nettoyage` fourni a déjà sauté à la fin), donc les deux matrices sont valides. `mat_afficher` attend un pointeur : on lui passe l'adresse des matrices, sans les copier.

```c
    mat_afficher("A", &a);
    mat_afficher("B", &b);
```

**4.b — Calculer le résultat** : l'opérateur `? :` choisit la fonction selon l'opération demandée (`addition` vaut 1 pour `add`, 0 pour `mul`). En cas d'échec, le message est écrit sur `stderr` avec la cause et les dimensions des deux matrices, puis on saute au point de nettoyage unique. `r` est alors resté vide (règle R3) et `statut` vaut encore `EXIT_FAILURE`, donc le programme se termine avec le code 1. Comme `a` et `b` sont des variables `Matrice` et non des pointeurs, on accède à leurs dimensions directement avec `.` (`a.nb_lignes`).

```c
    MatErreur err = addition ? mat_additionner(&a, &b, &r)
                             : mat_multiplier(&a, &b, &r);
    if (err != MAT_OK) {
        fprintf(stderr, "Erreur : calcul impossible : %s ",
                mat_message_erreur(err));
        fprintf(stderr, "(A : %d x %d, B : %d x %d)\n",
                a.nb_lignes, a.nb_colonnes, b.nb_lignes, b.nb_colonnes);
        goto nettoyage;
    }
```

Premier essai avec deux matrices de dimensions incompatibles (scénario 3) :

```text
$ ./demo_matrices add donnees/A.txt donnees/C.txt R.txt
A (4 x 3) :
       25       48       84
       15       33       11
       45       88       10
        0       12       -5
B (3 x 2) :
        1        0
        0        1
        2       -1
Erreur : calcul impossible : dimensions incompatibles (A : 4 x 3, B : 3 x 2)
$ echo $?
1
```

Le message indique la cause et les dimensions, et le code de sortie vaut 1 : c'est le comportement attendu.

**4.c — Afficher le résultat** :
on affiche `r` avec `mat_afficher`.
Le nom dépend de l'opération. Avec `? :`, on choisit `"R = A + B"` si `addition` vaut 1,
sinon `"R = A x B"`. On passe `&r` : la fonction reçoit l'adresse de la matrice, sans la copier.

```c
    mat_afficher(addition ? "R = A + B" : "R = A x B", &r);
```

**4.d — Signaler le succès** : *à compléter.*

#### Questions de réflexion

**Q6.1** — La bibliothèque renvoie seulement un code d'erreur, et c'est `main.c` qui décide quoi afficher. Ici on écrit sur `stderr` avec `mat_message_erreur`, en ajoutant le nom du fichier ou les dimensions, que seul `main` connaît. Si `mat_lire` faisait elle-même un `printf`, un programme graphique qui l'utiliserait ne pourrait pas afficher l'erreur dans une fenêtre : la bibliothèque ne serait plus réutilisable.

**Q6.2** — Dans `charger`, on lit le fichier. Quand on appelle `fclose`, toute la matrice
est déjà lue. Si `fclose` échoue, on ne perd rien.
Dans `sauvegarder`, on écrit le fichier. Les données peuvent rester dans le tampon et
être vraiment écrites seulement au moment du `fclose`. Si `fclose` échoue (par exemple
disque plein), le fichier peut être incomplet.
Il faut donc tester `fclose` dans `sauvegarder`. Sinon, le programme dirait
« Résultat enregistré » alors que le fichier est faux. C'est la même idée que `fflush` en Q4.4.

**Q6.3** — *à compléter.*

## 4. Vérifications mémoire

### test_ex1

```text
==2508== HEAP SUMMARY:
==2508==     in use at exit: 0 bytes in 0 blocks
==2508==   total heap usage: 11 allocs, 11 frees, 1,228 bytes allocated
==2508==
==2508== All heap blocks were freed -- no leaks are possible
==2508==
==2508== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)
```

Les 11 allocations sont toutes libérées, y compris lors des échecs d'allocation simulés : `mat_allouer` rend bien les lignes déjà obtenues quand une allocation échoue.

### test_ex2

Commande : `valgrind --leak-check=full ./test_ex2`

```text
==70878== HEAP SUMMARY:
==70878==     in use at exit: 0 bytes in 0 blocks
==70878==   total heap usage: 51 allocs, 51 frees, 49,976 bytes allocated
==70878==
==70878== All heap blocks were freed -- no leaks are possible
==70878==
==70878== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)
```

Les 51 allocations sont toutes libérées, y compris pour les six fichiers incorrects et l'échec d'allocation simulé : `mat_lire` détruit bien `tmp` sur chaque chemin d'erreur.

### test_ex3

Commande : `valgrind --leak-check=full ./test_ex3`

```text
==16206== HEAP SUMMARY:
==16206==     in use at exit: 0 bytes in 0 blocks
==16206==   total heap usage: 37 allocs, 37 frees, 1,412 bytes allocated
==16206==
==16206== All heap blocks were freed -- no leaks are possible
==16206==
==16206== ERROR SUMMARY: 0 errors from 0 contexts (suppressed: 0 from 0)
```

Les 37 allocations sont toutes libérées, y compris dans les cas d'erreur (dépassement et échec d'allocation simulé) : dans `mat_additionner` et `mat_multiplier`, chaque `return` d'erreur placé après `mat_allouer` est précédé de `mat_detruire(&r)`.

## 5. Démonstration
Nous avons lancé `demo_matrices` sur les scénarios du sujet. Pour chacun : la
commande, la sortie, et le code de retour avec `echo $?`.

### Scénario 3 — addition impossible

```text
$ ./demo_matrices add donnees/A.txt donnees/C.txt R.txt
A (4 x 3) :
       25       48       84
       15       33       11
       45       88       10
        0       12       -5
B (3 x 2) :
        1        0
        0        1
        2       -1
Erreur : calcul impossible : dimensions incompatibles (A : 4 x 3, B : 3 x 2)
$ echo $?
1
```

A et C n'ont pas les mêmes dimensions. Le programme affiche les dimensions, ne crée
pas `R.txt`, et s'arrête avec le code 1. C'est le comportement attendu.

### Scénario 4 — multiplication impossible

```text
$ ./demo_matrices mul donnees/A.txt donnees/B.txt R.txt
A (4 x 3) :
       25       48       84
       15       33       11
       45       88       10
        0       12       -5
B (4 x 3) :
        1        2        3
        4        5        6
        7        8        9
       10       11       12
Erreur : calcul impossible : dimensions incompatibles (A : 4 x 3, B : 4 x 3)
$ echo $?
1
```

A a 3 colonnes et B a 4 lignes : 3 ≠ 4, donc le produit n'existe pas.
Le programme s'arrête avec le code 1. C'est le comportement attendu.

### Scénario 5 — fichier absent

```text
$ ./demo_matrices add donnees/absent.txt donnees/B.txt R.txt
Erreur : impossible d'ouvrir "donnees/absent.txt" : No such file or directory
$ echo $?
1
```

Le fichier n'existe pas. Le programme affiche le nom du fichier et la cause donnée par
le système, puis s'arrête avec le code 1. C'est le comportement attendu.

### Scénario 6 — fichier mal formé

```text
$ ./demo_matrices add donnees/invalide.txt donnees/B.txt R.txt
Erreur : lecture de "donnees/invalide.txt" : fichier mal formé
$ echo $?
1
```

Le fichier contient une donnée qui n'est pas un entier. `mat_lire` renvoie
`MAT_ERR_FORMAT`, et le programme affiche le nom du fichier avec l'erreur, puis
s'arrête avec le code 1. C'est le comportement attendu.

### Scénario 7 — fichier tronqué

```text
$ ./demo_matrices add donnees/tronque.txt donnees/B.txt R.txt
Erreur : lecture de "donnees/tronque.txt" : fichier mal formé
$ echo $?
1
```

Il manque des coefficients à la fin du fichier. `mat_lire` détruit sa matrice
locale et renvoie `MAT_ERR_FORMAT`. Le programme s'arrête avec le code 1.
C'est le comportement attendu.

### Scénario 8 — dossier de sortie inexistant

```text
$ ./demo_matrices add donnees/A.txt donnees/B.txt pas_de_dossier/R.txt
A (4 x 3) :
       25       48       84
       15       33       11
       45       88       10
        0       12       -5
B (4 x 3) :
        1        2        3
        4        5        6
        7        8        9
       10       11       12
R = A + B (4 x 3) :
       26       50       87
       19       38       17
       52       96       19
       10       23        7
Erreur : impossible de créer "pas_de_dossier/R.txt" : No such file or directory
$ echo $?
1
```

Le calcul réussit, mais le dossier `pas_de_dossier` n'existe pas : `fopen` échoue
dans `sauvegarder`. Le programme affiche le nom du fichier et la cause, puis
s'arrête avec le code 1. C'est le comportement attendu. Les trois matrices
sont libérées au nettoyage (voir Q6.3).

### Scénario 9 — échec d'allocation

Ce cas ne peut pas être provoqué avec `demo_matrices`. Il est simulé dans
`test_ex2` et `test_ex3` (option `-DMAT_TEST_ALLOC`) : les vérifications
« (2.d) mat_lire renvoie MAT_ERR_ALLOCATION proprement » et « (3.f) echec
d'allocation : MAT_ERR_ALLOCATION, r vide » sont [OK], et valgrind ne trouve
aucune fuite (partie 4).

### Scénario 10 — arguments manquants

```text
$ ./demo_matrices add donnees/A.txt
Usage : ./demo_matrices <add|mul> <fichier_A> <fichier_B> <fichier_R>
$ echo $?
1
```

Il manque des arguments. Le programme affiche comment l'utiliser et s'arrête
avec le code 1. C'est le comportement attendu.

## 6. Bilan et difficultés

### Ce que nous avons compris

Le calcul matriciel lui-même était simple ; l'essentiel du travail a porté sur la mémoire et les erreurs. Nous avons compris qu'une allocation à deux niveaux impose de gérer l'échec partiel (libérer les lignes déjà obtenues, puis le tableau, dans cet ordre), et qu'un programme peut passer tous ses tests tout en ayant des fuites : seul valgrind permet de vérifier que chaque allocation a bien sa libération, y compris sur les chemins d'erreur. Nous avons aussi vu l'intérêt des règles de propriété : comme toute matrice est initialisée à `MATRICE_VIDE` et que `mat_detruire` la remet à vide, le nettoyage final de `main` peut détruire les trois matrices sans savoir lesquelles ont été créées.

### Difficultés rencontrées

- **Git à plusieurs** : quand un membre avait poussé des modifications, notre `git push` était refusé tant que nous n'avions pas fait `git pull`. 
- **Tabulations et espaces** : notre code était bien indenté dans l'éditeur mais pas sur GitHub. `cat -A` a montré des tabulations, affichées différemment selon les logiciels.

### Répartition du travail

- **Sana BEN CHAABANE** : 
exercice 3 (matrice_calcul.c, Q5.1 à Q5.4) ; exercice 4 : étape 4.c (main.c), réponse Q6.2 ;
Partie Démonstration (scénarios 1 à 10).
J’ai réalisé aussi les tests, les vérifications avec Valgrind et les scénarios de démonstration.

- **Nour AISSA** :
mise en place du dépôt GitHub (`Makefile`, `.gitignore`, vérification automatique) ;
exercice 1 (`matrice.c`, `matrice_alloc.c`, Q3.1 à Q3.4) ;
exercice 4 : étapes 4.a et 4.b (`main.c`), réponse Q6.1 ;
rédaction de la conception.

### Aides extérieures

- **Sana BEN CHAABANE (exercice 3 ; exercice 4 : étape 4.c, Q6.2 et Démonstration)** :
 J’ai utilisé Claude pour m’aider à comprendre certaines parties difficiles : les dépassements en 3.g et Q5.4, les pointeurs et `const` en Q5.1, et `fclose` en Q6.2. Il m’a aussi aidée à corriger mon code et à trouver certaines commandes de compilation.

- **Nour AISSA (exercice 1 ; exercice 4 : étapes 4.a, 4.b et Q6.1 ; conception)** :
J'ai utilisé Claude pour m'aider à comprendre certaines étapes du sujet et des messages du compilateur, et pour m'aider à rédiger et mettre en forme le compte rendu. J'ai écrit mon code, lancé les tests et valgrind, et relu et adapté les textes ia.


