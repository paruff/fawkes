# Prometheus Notes

We are using the prometheus-operator from CoreOs which deploys (Prometheus, AlertMgr, and Grafana).

Currently, in additional to gathering metics/statistics on the overall cluster, an example is provided for pulling/scraping metrics from an application endpoint.
To that end Jenkins has been updated with the Prometheus plugin and a Scrape Configuration job was added to Prometheus to pull the available metrics from Jenkins.

The technical solution for achieving this was not intuitive.  See prometheums-values.yaml.
Note: This is not the prometheus.yaml but rather the config for the prometheums operator itself--which indirectly generates the prometheus configuration.
Therein lies the rub.  The default values yaml for the prometheus operator are misleading.

DO NOT: configure new/additional jobs under "# additionalScrapeConfigs: []" in prometheus-values.yaml

DO: instead set "additionalScrapeConfigsExternal: true"

Next: add scrape configuration jobs in additional-scrape-configs.yaml.  follow the pattern from:
https://prometheus.io/docs/prometheus/latest/configuration/configuration/#<scrape_config>

From here a kubernetes secret must be created (following a very specific convention that one would not likely find readily).

kubectl create secret generic --namespace pipeline prometheus-prometheus-oper-prometheus-scrape-confg --from-file=additional-scrape-configs.yaml

That is the secret sauce.  That exact secret must exist in order for the Prometheus-Operator to:

1. know to look for additional scrape configuration jobs
2. pull the the jobs and place in the correct location in the prometheus.yaml file.