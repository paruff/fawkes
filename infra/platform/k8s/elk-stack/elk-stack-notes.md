# ELK/EFK Notes

## Fluent-bit

This current configuration uses Fluent-bit and not Fluentd or Logstash. The default pattern is being used for the chart to pull kubernetes logs. Log data is being save to ElasticSearch into index: kubernetes_cluster\* (one for each day).

## IMPORTANT

The default ElasticSearch URL had to be overridden. See elk-values.yaml (Kibana section). Note also that the Environment variable setting was insuffecient. It was necessary to define the creation of file: kibana.yml and to set the elasticsearch.url there.

## Custom Configurations

See the nested conf directory. Those files are not currently used. However, if the need arises to fine-tune the inputs/outputs/patterns/parsers then these files can serve as a guide or starting point.
