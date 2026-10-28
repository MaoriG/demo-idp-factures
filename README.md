# 🧾 Démo IDP — Traitement automatique de factures fournisseurs

**Le problème, en une phrase :** chaque semaine, une entreprise reçoit des factures PDF de dizaines de fournisseurs, chacune avec une mise en page différente. Quelqu'un doit les ouvrir, recopier les champs à la main, décider du circuit de paiement. C'est lent, c'est sujet aux erreurs, et il n'y a aucune trace de qui a décidé quoi.

**Ce projet montre la solution :** un flux d'automatisation qui lit les factures, en extrait les informations, les archive dans un tableur, et applique une règle de bon sens — *les petites factures sont payées automatiquement, les grosses sont soumises à un humain*.

Tout est traité en **moins de 2 secondes**, sans intervention humaine — sauf quand il en faut une.

---

## Ce que ça donne concrètement

Quatre factures de test, quatre fournisseurs, quatre mises en page complètement différentes :

| Facture | Fournisseur | Montant | Décision du flux |
|---|---|---|---|
| facture-nordtech.pdf | NordTech Solutions | 1 245,60 € | 👤 **Validation humaine** (> 1 000 €) |
| facture-alpaca.pdf | Alpaca Office | 189,90 € | ✅ **Paiement automatique** |
| facture-batisud.pdf | Bâtisud Matériaux | 3 490,00 € | 👤 **Validation humaine** (> 1 000 €) |
| facture-cloudsys.pdf | CloudSys Europe | 79,99 € | ✅ **Paiement automatique** |

Et pour chaque facture, une ligne dans [`exemples/resultats.csv`](exemples/resultats.csv) : fournisseur, numéro, date, montants, décision. **Une trace propre, exploitable dans n'importe quel outil.**

Le principe clé : **l'humain n'intervient que sur les exceptions.** C'est ce qu'on appelle le *human-in-the-loop* — l'automatisation fait le volume, l'humain garde les décisions qui comptent.

## Deux implémentations du même cas d'usage

Ce cas d'usage a été construit **deux fois**, dans deux orchestrateurs différents — pour montrer que les concepts (extraction, routage, human-in-the-loop, traçabilité) se transposent d'un outil à l'autre :

| | [Version n8n](workflow/) | [Version UiPath](uipath/) |
|---|---|---|
| **Outil** | n8n — orchestrateur open source, auto-hébergé | UiPath Studio Community — plateforme RPA |
| **Extraction** | nœud Code (JavaScript) + expressions régulières | 5 activités Assign (VB) + expressions régulières |
| **Validation humaine** | branche dédiée du workflow | boîte de dialogue interactive (Input Dialog) |
| **Sortie** | `resultats.csv` | `resultats.csv` — mêmes colonnes |

Même logique, deux outils : le choix de l'outil est une décision de contexte et de ROI, pas une fin en soi.

## Comment ça marche (sans jargon)

Le flux est une **chaîne d'étapes**, comme une recette :

```
📂 Lire les factures (4 fichiers PDF)
   → 📄 En extraire le texte
   → 🔍 Repérer les informations (fournisseur, n°, date, montants)
   → 💰 Appliquer la règle : plus de 1 000 € ?
        ├── OUI → 👤 envoyer en validation humaine
        └── NON → ✅ payer automatiquement
   → 📊 Tout consigner dans un fichier CSV
```

L'étape 🔍 repère les informations en s'appuyant sur les **libellés** (« Émetteur : », « Facture n° : », « Total TTC : »). C'est pour ça que la mise en page peut changer d'un fournisseur à l'autre : on lit les étiquettes, pas la décoration.

**Et les documents scannés ?** Un PDF scanné est une image : il faut d'abord le « lire » avec un outil de reconnaissance de texte (OCR), puis — pour les cas vraiment tordus — un modèle d'IA de langage fait l'extraction. Ce flux est conçu pour accueillir cette brique : la lecture par libellés reste là en **filet de sécurité déterministe** — si l'IA n'est pas disponible, le flux continue de fonctionner sur les documents standards.

## L'essayer chez soi

**Option A — avec n8n** :

1. Installer [n8n](https://n8n.io) (outil d'automatisation open source — version d'essai cloud ou installation locale)
2. Dans n8n : importer le fichier [`workflow/idp-demo.json`](workflow/idp-demo.json)
3. Cliquer **Execute workflow** → les 4 factures de [`factures/`](factures/) sont traitées et le CSV apparaît

**Option B — avec UiPath** :

1. Installer [UiPath Studio Community](https://www.uipath.com/fr/studio-community) (gratuit)
2. Ouvrir [`uipath/Main.xaml`](uipath/Main.xaml) — le détail est dans le [README UiPath](uipath/README.md)
3. **Exécuter fichier (F5)** → le robot lit les factures et ouvre une boîte de validation pour chaque facture de plus de 1 000 €

Aucune clé API, aucun abonnement : tout tourne en local.

## Reproduire les factures de test

Les PDF de test sont régénérables depuis leurs sources HTML :

```powershell
powershell -File scripts/generer-factures.ps1
```

## Pour les curieux (côté technique)

- **Outils** : [n8n](https://n8n.io) (le workflow entier tient dans un JSON versionné dans ce dépôt) et [UiPath Studio Community](https://www.uipath.com/fr/studio-community) (processus XAML dans [`uipath/`](uipath/))
- **Extraction** : expressions régulières ancrées sur les libellés + normalisation du format numérique français (« 1 245,60 » → `1245.6`)
- **Routage** : condition numérique strictement typée (> 1 000 € → humain), testée sur les 4 cas
- **Traçabilité** : flag qualité par facture (`extraction_ok`) — en production, il alimente une file d'exceptions
- **Deux bugs réels corrigés** pendant la construction (casse des libellés, extraction PDF d'une mise en page en colonnes) — détaillés dans le [README UiPath](uipath/README.md), avec les leçons qui vont avec
- **En production on remplacerait** : le déclencheur manuel par une boîte mail ou un scan-post ; l'écriture CSV par un ERP ; la validation humaine par une approbation par mail/Teams avec délai d'escalade ; et l'identification des factures reposerait sur leur numéro pour garantir qu'aucune n'est payée deux fois

## Auteur

**Maori Gobert** — [github.com/MaoriG](https://github.com/MaoriG) · gobertmaori@gmail.com

Projet de démonstration réalisé de manière autonome, workflows testés et vérifiés de bout en bout dans les deux implémentations.
