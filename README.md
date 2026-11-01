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

**Q3.1** — `mat_detruire` prend un `Matrice *` pour pouvoir modifier la variable de l'appelant : après les `free`, elle la remet à `MATRICE_VIDE`. Avec un passage par valeur, la fonction travaillerait sur une copie : la mémoire serait bien libérée, mais la variable de l'appelant garderait dans `coef` l'adresse d'une zone déjà rendue. Utiliser ensuite cette matrice serait un accès invalide, et un second appel à `mat_detruire` libérerait une deuxième fois la même mémoire (double `free`, comportement indéfini).

**Q3.2** — Une matrice n × p demande 1 + n appels à `calloc` (le tableau de n pointeurs, puis une ligne de p entiers pour chaque ligne) et autant d'appels à `free`. Si la k-ième allocation échoue : pour k = 1, c'est le tableau `coef` qui manque et il n'y a rien à libérer ; pour k ≥ 2, on a obtenu le tableau et k − 2 lignes, donc `mat_allouer` doit faire k − 1 libérations. Par exemple, si la ligne 2 échoue (k = 4), on libère `coef[1]`, `coef[0]` puis `coef`, soit 3 libérations.

**Q3.3** — Après le premier appel, la matrice vaut `MATRICE_VIDE`, donc `coef` vaut `NULL` : au second appel, le test `if ((*m).coef != NULL)` est faux et rien n'est libéré. Ce n'est plus vrai avec une copie `Matrice b = a;` : seul le pointeur `coef` est copié (copie superficielle), et `a` et `b` partagent les mêmes lignes. `mat_detruire(&a)` libère cette mémoire et remet `a` à vide, mais `b` garde les anciennes adresses : `mat_detruire(&b)` libère donc une seconde fois la même mémoire, c'est un double `free`.

**Q3.4** — Cette affectation garantit que toutes les sorties en erreur laissent `*res` vide (règle R3), y compris le refus des dimensions en 1.c, qui a lieu avant toute allocation. Quel que soit le chemin suivi, l'appelant reçoit soit une matrice complète (`MAT_OK`), soit une matrice vide, jamais un contenu indéterminé : il peut toujours appeler `mat_detruire` sans risque. Sans cette ligne, `*res` garderait son ancien contenu (des valeurs quelconques si la variable n'était pas initialisée), et un `mat_detruire` pourrait libérer une adresse invalide.

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

**Q5.1** — Non. Dans `mat_additionner`, `a` est de type `const Matrice *` : c'est la structure qui est constante, donc ses trois champs (`coef`, `nb_lignes`, `nb_colonnes`). Le compilateur refuse `a->nb_lignes = 0;` ou `a->coef = NULL;`. Mais `a->coef` est de type `int **` : les entiers vers lesquels il pointe ne sont pas constants, donc `a->coef[0][0] = 7;` compile sans erreur. Le `const` protège donc les dimensions et l'adresse du tableau, pas les coefficients. Pour que le compilateur refuse cette affectation, il faudrait que les coefficients soient eux-mêmes constants, par exemple un champ de type `const int *const *coef` (ou une copie de ce pointeur de ce type dans la fonction). Dans notre code, c'est donc nous qui respectons la règle R4 : on lit `a->coef[i][j]` mais on n'écrit que dans `r.coef[i][j]`.

**Q5.2** — Mathématiquement, a ← a + b a un sens, mais avec notre implémentation ce serait faux. La première chose que fait `verifier_parametres` est `*res = MATRICE_VIDE;`. Si `res` était `&a`, cette ligne viderait `a` avant le calcul : l'adresse de ses lignes serait perdue (fuite de mémoire) et `a` ne serait plus valide. Et même sans cette ligne, à la fin `*res = r;` écraserait `a.coef` par le nouveau tableau sans libérer l'ancien : encore une fuite. C'est pour cela que `res == a` ou `res == b` renvoie `MAT_ERR_ARGUMENT` sans rien modifier (règle R5), ce que vérifie le test « resultat = entree refuse, a reste intacte ». Pour faire a ← a + b, l'appelant calcule dans une nouvelle matrice, détruit l'ancienne `a`, puis garde le résultat.

**Q5.3** — Pour chaque coefficient du résultat (n × q cases), la boucle sur `k` fait p multiplications. Au total : **n × p × q** multiplications. Pour deux matrices 1000 × 1000 : 1000 × 1000 × 1000 = **10⁹**, soit un milliard de multiplications.

**Q5.4** — En C, le dépassement d'un `int` signé est un **comportement indéfini** : la norme ne dit pas ce qui se passe. Une fois que `int s = a + b;` a débordé, il est trop tard : le résultat peut être n'importe quoi, et le compilateur a le droit de supposer qu'un dépassement n'arrive jamais. Il peut donc considérer que `s < a` est toujours faux (pour b positif) et supprimer le test. De plus, ce test ne marche pas si `b` est négatif. Il faut donc détecter le problème **avant** de calculer. Nous calculons dans un type plus grand (`long long`), où la somme ou le produit de deux `int` ne peut pas déborder, puis nous vérifions que le résultat tient dans un `int` avec `tient_dans_int`.

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

**4.c — Afficher le résultat** : *à compléter.*

**4.d — Signaler le succès** : *à compléter.*

#### Questions de réflexion

**Q6.1** — Les fonctions de la bibliothèque (`mat_lire`, `mat_additionner`, …) ne font que renvoyer un code `MatErreur` : elles ne savent pas comment le programme qui les utilise communique avec l'utilisateur. C'est l'appelant qui décide quoi afficher et où. Dans notre `main.c`, c'est un programme en ligne de commande : le message est écrit sur `stderr` grâce à `mat_message_erreur(err)`, et nous le complétons avec des informations que seul `main` connaît (le nom du fichier dans `charger`, les dimensions de A et B à l'étape 4.b). Si `mat_lire` affichait elle-même un message avec `printf`, un programme graphique qui réutiliserait la bibliothèque verrait ce texte partir dans un terminal invisible, au lieu de pouvoir l'afficher dans une fenêtre de dialogue, le traduire ou réessayer avec un autre fichier. Garder la bibliothèque silencieuse la rend donc réutilisable dans n'importe quel programme.

**Q6.2** — *à compléter.*

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

## 6. Bilan et difficultés


