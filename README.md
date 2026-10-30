# TD — Stockage de matrices en C

- **Membres** : Prénom NOM (@pseudo), Prénom NOM (@pseudo), Prénom NOM (@pseudo)
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

#### Questions de réflexion

**Q4.1** — Notre `mat_lire` remplit d'abord une matrice locale (un brouillon) et ne l'affecte à `*res` qu'une fois toutes les lectures sont réussies. Ainsi, si une lecture échoue, il suffit de détruire `tmp` et l'appelant reçoit une matrice vide. Comme ça, il ne reçoit jamais une matrice à moitié remplie qui a l'air valide. Par exemple, dans le fichier `2 2 / 1 2 3` du test "coefficient manquant", il manque un quatrième nombre. Sans `tmp`, `res` contiendrait `[1 2] [3 0]`, le 0 est inventé par `calloc`, c'est une matrice qui a l'air valide mais son contenu est faux. On aurait pu écrire directement dans `res` mais il suffit d'oublier un `mat_detruire` et l'appelant aura une matrice fausse. Avec `tmp` le même oubli provoque une fuite de mémoire que valgrind détecte mais `res` reste vide. 

**Q4.2** — Non, la lecture ne vérifie pas que chaque ligne de la matrice est sur sa propre ligne de texte. L'appel `fscanf(f, "%31s", mot)` dans `lire_entier` lit un mot en sautant tous les blancs. Pour `mat_lire`, le fichier n'est donc qu'une suite de nombres, et un fichier `2 2` suivi de `1 2 3 4` sur une seule ligne donne la même matrice que s'il était écrit sur deux lignes.
- Ce n'est pas gênant, car ce qui détermine la matrice n'est pas la mise en page mais le nombre de coefficients et leur ordre. Le nombre de lectures est fixé par les dimensions lues au début du fichier, et les coefficients sont rangés dans l'ordre, ligne par ligne. Le contenu reste vérifié strictement : un coefficient manquant, un mot non numérique ou un entier trop grand donnent `MAT_ERR_FORMAT`. Le test « espaces et sauts de ligne en trop sont tolérés » passe d'ailleurs en `[OK]`. Nous sommes donc tolérants sur la forme (les blancs), mais stricts sur le contenu (les nombres).
- Strict en écriture, parce que le fichier que nous écrivons sera lu par d'autres : `mat_ecrire` produit toujours le même format (un seul espace entre deux nombres, aucun espace en fin de ligne), que n'importe quel lecteur, même exigeant, peut relire, et que l'on peut comparer caractère par caractère. Tolérant en lecture, parce que les fichiers lus peuvent venir de n'importe où, par exemple d'une personne qui tape une matrice à la main : on accepte les petites différences de mise en page, car seuls les nombres comptent. C'est le principe de robustesse (loi de Postel) : « être conservateur dans ce que l'on envoie, libéral dans ce que l'on accepte ».

**Q4.3** —

**Q4.4** —

#### Résultat du test

### Exercice 3 — Calcul matriciel

### Exercice 4 — Démonstration complète

## 4. Vérifications mémoire

## 5. Démonstration

## 6. Bilan et difficultés