# Manifest Diff

## `action.yaml`
Defines the manifest diff action.

**What it does?**
- Installs `skipctl`
- Runs the `diff.sh` script


## `diff.sh`
Contains the script logic.

**What it does?**
- Finds all manifest files inside subdirectories of `INPUTS_PATH` and groups them based on directory suffix (`-dev` or `-prod`).
- Runs `skipctl manifests diff` on these files
- Formats the output with a HTML `<details>` tag
- Outputs the results to `GITHUB_OUTPUT`

## How to test the script

1. Update files in `test-env/test-dev` and/or `test-env/test-prod`
2. Run the test script `./test.sh`
3. The output should look something like this

````shell
=== PROD DIFF ===
<details>
  <summary><b>test-env/test-prod/manifest.jsonnet DIFF</b></summary>

```diff
--- remote /test-env/test-prod/manifest.jsonnet
+++ local /test-env/test-prod/manifest.jsonnet
@@ -9,7 +9,7 @@
     },
     "spec": {
        "image": "test",
-       "port": 5000
+       "port": 3000
     }
  }

```
</details>

=== DEV DIFF ===
<details>
  <summary><b>test-env/test-dev/manifest.jsonnet DIFF</b></summary>

```diff
--- remote /test-env/test-dev/manifest.jsonnet
+++ local /test-env/test-dev/manifest.jsonnet
@@ -9,7 +9,7 @@
     },
     "spec": {
        "image": "test",
-       "port": 50002
+       "port": 3000
     }
  }

```
</details>
````
4. Alternatively, paste this in a GitHub markdown text-area and click "preview" to see that it is formatted correctly.
