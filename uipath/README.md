# Version UiPath — le même cas d'usage, reconstruit dans un second outil

La [version n8n](../README.md) de ce projet a été conçue en une soirée. Celle-ci en est la **transposition fidèle dans UiPath Studio Community** : mêmes factures, mêmes règles de routage, même sortie CSV — un autre orchestrateur.

Le message de cette double implémentation : ce qui compte dans l'automatisation, ce sont les **concepts** (extraction, normalisation, routage, human-in-the-loop, traçabilité) — ils se transposent d'un outil à l'autre. L'outil se choisit selon le contexte et le ROI, pas l'inverse.

---

## Le flux

```
▶ Message Box (« Traitement des factures — démo IDP UiPath »)
   → For Each (Directory.GetFiles(facturesDir, "*.pdf"))
        → Read PDF Text           (package UiPath.PDF.Activities)
        → Assign × 5              (extraction par expressions régulières VB)
        → If montantTTC > 1000
             ├── THEN  Input Dialog « Validation humaine » → oui/non
             └── ELSE  Assign « paiement automatique »
        → Assign : accumulation de la ligne CSV
   → Write Text File  (resultats.csv)
   → Message Box (« Terminé ! 4 factures traitées »)
```

L'étape de validation humaine est **réellement interactive** : pour chaque facture de plus de 1 000 €, une boîte de dialogue affiche le détail (n°, fournisseur, montant) et demande d'approuver ou de refuser. La décision est tracée dans le CSV.

## Ouvrir le projet

1. Installer [UiPath Studio Community](https://www.uipath.com/fr/studio-community) (gratuit) — projet testé sur Studio 2021.4 (VB, design classique)
2. Ouvrir `Main.xaml` (ou `project.json`) depuis ce dossier
3. Si la dépendance n'est pas restaurée : **Gérer les packages** → installer `UiPath.PDF.Activities` (version 3.x compatible avec votre Studio)
4. Ajuster la variable `facturesDir` (valeur par défaut dans le panneau Variables) vers le dossier [`factures/`](../factures/) de ce dépôt
5. **Exécuter fichier (F5)** — 2 ou 3 dialogues de validation apparaissent, puis `resultats.csv` est écrit

## L'extraction, champ par champ

Cinq activités `Assign` avec des expressions régulières ancrées sur les libellés du document :

| Champ | Expression (VB) |
|---|---|
| Fournisseur | `Regex.Match(textePDF, "Émetteur\s*:?\s*([A-Z][^\r\n]+)").Groups(1).Value.Trim` |
| N° facture | `Regex.Match(textePDF, "Facture\s*n°\s*:?\s*([A-Z0-9-]+)").Groups(1).Value.Trim` |
| Date | `Regex.Match(textePDF, "Date\s*:?\s*(\d{2}/\d{2}/\d{4})").Groups(1).Value.Trim` |
| Total TTC (texte) | `Regex.Match(textePDF, "Total\s*TTC\s*:?\s*([\d\s\xA0]+,\d{2})", RegexOptions.IgnoreCase).Groups(1).Value.Trim` |
| Montant (nombre) | `If(ttcTxt = "", 0, CDbl(ttcTxt.Replace(" ", "").Replace(Chr(160), "").Replace(",", ".")))` |

La dernière ligne gère le **format numérique français** : espaces (y compris insécables, `Chr(160)`) dans « 1 245,60 », virgule décimale convertie en point pour la comparaison numérique.

## Exemple de sortie (`resultats.csv`)

```
fichier;fournisseur;numero;date;montant_ttc;route
facture-alpaca.pdf;Alpaca Office SARL;AO-8817;05/10/2026;189.90;paiement automatique
facture-batisud.pdf;Bâtisud Matériaux SA;BS-F-2026-1109;28/09/2026;3490.00;validation humaine — approuvé
facture-cloudsys.pdf;CloudSys Europe SAS;CS-EU-26-0937;01/10/2026;79.99;paiement automatique
facture-nordtech.pdf;NordTech Solutions SAS;NT-2026-04412;12/10/2026;1245.60;validation humaine — approuvé
```

## Deux vrais bugs rencontrés, deux leçons

Le flux a été débuggé sur les 4 factures réelles du dépôt. Deux incidents méritent le détour :

1. **« TOTAL TTC » en majuscules** (facture Bâtisud) — la regex, sensible à la casse, ne matchait plus : montant extrait à 0,00, facture mal routée en paiement automatique. **Correctif : `RegexOptions.IgnoreCase`.** Leçon : un parser d'extraction doit être testé contre tous les formats réellement rencontrés, pas contre un seul gabarit.

2. **Facture en deux colonnes** (facture CloudSys) — l'extracteur PDF restitue le texte ligne par ligne : deux colonnes côte à côte se retrouvent concaténées sur la même ligne, ce qui polluait les champs voisins. **Correctif : garder les libellés et leurs valeurs sur la même ligne visuelle.** Leçon : en IDP, la mise en page du document conditionne la fiabilité de l'extraction ; sur des mises en page non contrôlées (vrais fournisseurs), on passe à l'OCR + modèle IA de langage — le filet de sécurité par libellés reste utile pour les documents standards.

## Équivalences n8n ↔ UiPath

| Concept | n8n | UiPath |
|---|---|---|
| Conteneur de flux | Workflow | Processus (Séquence) |
| Unité d'exécution | Nœud | Activité |
| Itération sur fichiers | Nœud de lecture de fichiers | `For Each` + `Directory.GetFiles` |
| Extraction texte PDF | Nœud d'extraction | `Read PDF Text` (package PDF) |
| Logique personnalisée | Nœud Code (JavaScript) | `Assign` (VB) |
| Condition | Nœud IF | Activité `If` |
| Interaction humaine | Branche d'attente de validation | `Input Dialog` (boîte de dialogue) |
| Écriture du résultat | Nœud d'écriture fichier | `Write Text File` |

En entreprise, le processus UiPath serait publié sur **Orchestrator** : files d'attente, tentatives automatiques, ordonnancement, supervision, et la validation humaine passerait d'une boîte de dialogue à une approbation mail/Teams avec délai d'escalade.
