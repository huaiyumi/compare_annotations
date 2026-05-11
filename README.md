# Compare GO Annotations

This workflow compares Gene Ontology (GO) annotations from two different sources.

The process is adapted from the section *“Estimating the reliability of PAN-GO annotation”* from the PAN-GO Nature paper:
[https://www.nature.com/articles/s41586-025-08592-0](https://www.nature.com/articles/s41586-025-08592-0)

---

## Overview

The pipeline consists of two main steps:

1. Generate a GO parent lookup file
2. Compare GO annotations between prediction and reference datasets

---

## Step 1: Generate the GO Parent File

This step creates a lookup file containing all parent GO terms.

### Instructions

1. Download the GO ontology file:
   [https://current.geneontology.org/ontology/go-basic.obo](https://current.geneontology.org/ontology/go-basic.obo)

2. Run the script:

```bash
perl findGOparent_OBO.pl -i go-basic.obo > goparents
```

### Notes

* Only `is_a` and `part_of` relationships are used
* All relationships remain within the same GO aspect

### Output Format (`goparents`)

| Column | Description                                             |
| ------ | ------------------------------------------------------- |
| 1      | Child term                                              |
| 2      | Parent term                                             |
| 3      | Relationship (`is_a`, `part_of`, or blank for indirect) |
| 4      | GO aspect                                               |

### Example

```
protein serine kinase activity(GO:0106310)    protein kinase activity(GO:0004672)    is_a    molecular_function
protein serine kinase activity(GO:0106310)    catalytic activity(GO:0003824)          molecular_function
```

---

## Step 2: Compare GO Annotations

This step compares GO annotations from two datasets:

* Predicted GO annotations
* Experimentally supported (reference) GO annotations

---

### Script

`compare_GO_annotation.pl`

---

### Input Files

The script requires:

1. **Prediction file** — predicted GO annotations
2. **Reference file** — experimentally supported GO annotations

#### File Format (both inputs)

| Column | Description     |
| ------ | --------------- |
| 1      | Gene identifier |
| 2      | GO ID           |

---

### Usage

```bash
perl compare_GO_annotation.pl \
  -p <predicted_file> \
  -r <reference_file> \
  -g <go_parents_file>
```

### Example

```bash
perl compare_GO_annotation.pl \
  -p test_predicted \
  -r test_reference \
  -g goparents | more
```

---

## Output Format

| Column | Description        |
| ------ | ------------------ |
| 1      | Gene identifier    |
| 2      | GO ID (prediction) |
| 3      | GO ID (reference)  |
| 4      | Mapping type       |

---

## Mapping Types

### 1. `direct`

* Predicted and reference GO terms are identical

---

### 2. `true`

* Predicted term is **more general** than the reference

**Example:**

* Prediction: protein kinase activity (GO:0004672)
* Reference: protein serine kinase activity (GO:0106310)
* Since the reference term *is_a* child of the prediction → **true**

---

### 3. `related`

* Predicted term is **more specific** than the reference

**Example:**

* Prediction: protein serine kinase activity (GO:0106310)
* Reference: protein kinase activity (GO:0004672)
* Prediction is more specific → **related**

---

### 4. `unrelated`

* Predicted and reference GO terms are not related

---

### 5. `no map`

* The gene has no corresponding annotation exists in the reference file

---

## Mapping Confidence Hierarchy

```
direct > true > related > unrelated > no map
```

---

## Notes on Mapping Behavior

* A **high-confidence match** (e.g., `direct`) may also produce additional lower-confidence matches (`true`, `related`) for the same prediction
* A **lower-confidence match** (e.g., `related`) will not have a corresponding higher-confidence match (`direct`, `true`)


