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

## 3. Réalisation

### Exercice 1 — Allocation et destruction

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

### Exercice 4 — Démonstration complète

## 4. Vérifications mémoire

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

## 5. Démonstration

## 6. Bilan et difficultés