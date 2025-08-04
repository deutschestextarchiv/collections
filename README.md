# DTA collections metadata

This repository contains descriptions of collections of historical texts.
The collections are part of [Deutsches Textarchiv (DTA)](https://www.deutschestextarchiv.de/).
All descriptions are available as YAML files.

The directory [`schemata`](schemata) contains corresponding JSON schema files (in YAML format) as well as a script
which can be used for validation.

The descriptions of DTA collections where created in the context of [Text+](https://www.text-plus.org/).

All files are being made accessible within the DTA infrastructure under a Creative Commons licence.

## Content

This repository provides:

- [`dta`](dta): contains full descriptions of collections of historical texts within DTA
- [`textplus`](textplus): contains a reduced collection registry-description as basis for discussion within Text+
- [`schemata`](schemata): contains schema files as well as script for validating

## HOWTO

Validate datasets:

```bash
schemata/validate-against-schema.pl --schema=schemata/dta.yml dta/*.yml dwds/*.yml
```

Publish dataset for https://www.deutschestextarchiv.de/textplus/:

```bash
schemata/generate-and-publish-datasets.sh
```

Publish landing pages for https://www.deutschestextarchiv.de/sammlungen/:

```bash
make -C landing-pages landing-pages && make -C landing-pages publish
```

Publish box listing for https://www.dwds.de/collections/:

```bash
perl schemata/compile-catalog.pl dta/*.yml dwds/*.yml > presentation/catalog.json
rsync -av presentation/ kaskade:/var/www/collections
```
