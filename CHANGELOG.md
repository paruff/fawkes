# Changelog

All notable changes to the Fawkes platform will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.35](https://github.com/paruff/fawkes/compare/v0.3.34...v0.3.35) (2026-09-05)


### Docs

* add golden path verification planes reference ([#1774](https://github.com/paruff/fawkes/issues/1774)) ([1b303a6](https://github.com/paruff/fawkes/commit/1b303a6816d9c3a5b65dbd4b3842f0478c5d1a22))


### Chores

* **golden-path:** retrigger tracer-bullet and smart-alerting CI ([#1775](https://github.com/paruff/fawkes/issues/1775)) ([90e12ca](https://github.com/paruff/fawkes/commit/90e12ca2cd2895886f67a7c10390c5839d5a081d))

## [0.3.34](https://github.com/paruff/fawkes/compare/v0.3.33...v0.3.34) (2026-09-05)


### Fixed

* **ci:** pin Trivy to v0.74.0 in reusable-security-scanning.yml ([#1771](https://github.com/paruff/fawkes/issues/1771)) ([9ceee8b](https://github.com/paruff/fawkes/commit/9ceee8b52f7981f22891d9595c08b8a43254ba32))

## [0.3.33](https://github.com/paruff/fawkes/compare/v0.3.32...v0.3.33) (2026-09-05)


### Chores

* **tracer-bullet:** bump version to 0.1.1 ([#1768](https://github.com/paruff/fawkes/issues/1768)) ([e180392](https://github.com/paruff/fawkes/commit/e180392062b47f836df386b79ad87d531bd3bce9))

## [0.3.32](https://github.com/paruff/fawkes/compare/v0.3.31...v0.3.32) (2026-09-05)


### Fixed

* **gitops:** exclude golden-path apps from ApplicationSet auto-discovery ([#1767](https://github.com/paruff/fawkes/issues/1767)) ([7b35e09](https://github.com/paruff/fawkes/commit/7b35e097e2151464050ddc10431ededfd1781d77))

## [0.3.31](https://github.com/paruff/fawkes/compare/v0.3.30...v0.3.31) (2026-09-05)


### Fixed

* **ci:** install syft before SBOM attestation in reusable-image-signing ([#1765](https://github.com/paruff/fawkes/issues/1765)) ([6f0b09f](https://github.com/paruff/fawkes/commit/6f0b09f894cbc76bf2dc55a55c44c7f7e31340cc))

## [0.3.30](https://github.com/paruff/fawkes/compare/v0.3.29...v0.3.30) (2026-09-05)


### Docs

* correct BACKLOG and DEPLOYMENT_STRATEGY against live state ([#1761](https://github.com/paruff/fawkes/issues/1761)) ([b5e0f2b](https://github.com/paruff/fawkes/commit/b5e0f2bf7a982f5d02e3e4ca618ef68970473397))

## [0.3.29](https://github.com/paruff/fawkes/compare/v0.3.28...v0.3.29) (2026-09-05)


### Fixed

* **infra:** remove hardcoded storageClass: standard, fix ArgoCD namespace watch ([#1759](https://github.com/paruff/fawkes/issues/1759)) ([37b6bce](https://github.com/paruff/fawkes/commit/37b6bce327b085f432d2dff4ffe6d5197011cf08))

## [0.3.28](https://github.com/paruff/fawkes/compare/v0.3.27...v0.3.28) (2026-09-05)


### Fixed

* **security:** resolve 4 of 5 open Dependabot npm alerts in design-system ([#1757](https://github.com/paruff/fawkes/issues/1757)) ([b2dad85](https://github.com/paruff/fawkes/commit/b2dad850e40e5d8c5937d0249570e738c1e01994))

## [0.3.27](https://github.com/paruff/fawkes/compare/v0.3.26...v0.3.27) (2026-09-05)


### Fixed

* **terraform:** activate Azure Blob remote state backend for infra/azure ([#1755](https://github.com/paruff/fawkes/issues/1755)) ([8138d4b](https://github.com/paruff/fawkes/commit/8138d4b8b408bbf6d86fa921206fbceac9446302))

## [0.3.26](https://github.com/paruff/fawkes/compare/v0.3.25...v0.3.26) (2026-09-05)


### Fixed

* **smart-alerting:** add auth (AUD-2) and fix a service-breaking import bug ([#1753](https://github.com/paruff/fawkes/issues/1753)) ([2702b65](https://github.com/paruff/fawkes/commit/2702b659c2212faa8f18d02660857d4b2e96d214))


### Chores

* **deps:** bump the npm_and_yarn group across 1 directory with 9 updates ([#1752](https://github.com/paruff/fawkes/issues/1752)) ([62bdc26](https://github.com/paruff/fawkes/commit/62bdc267efc805d5a4856b1e3fa28e5010707b38))

## [0.3.25](https://github.com/paruff/fawkes/compare/v0.3.24...v0.3.25) (2026-09-05)


### Changed

* **postgresql:** consolidate 11 single-tenant CNPG Clusters into one shared cluster ([#1749](https://github.com/paruff/fawkes/issues/1749)) ([c879cbf](https://github.com/paruff/fawkes/commit/c879cbf24b4b812bf36f9b95fdf1449c2131acea))

## [0.3.24](https://github.com/paruff/fawkes/compare/v0.3.23...v0.3.24) (2026-09-05)


### Fixed

* **pipeline:** bump all CNPG Postgres clusters to 17.11, fix segfaulting 16.4 ([#1746](https://github.com/paruff/fawkes/issues/1746)) ([7edfc07](https://github.com/paruff/fawkes/commit/7edfc07dc4895d80aff4eedb74114745897255b4))

## [0.3.23](https://github.com/paruff/fawkes/compare/v0.3.22...v0.3.23) (2026-09-05)


### Fixed

* **pipeline:** fix Jenkins deploy-blocking bugs, CNPG managed.services API break ([#1744](https://github.com/paruff/fawkes/issues/1744)) ([ce89f16](https://github.com/paruff/fawkes/commit/ce89f1666fc69f0e65a4c366221bb80d580c9f4e))

## [0.3.22](https://github.com/paruff/fawkes/compare/v0.3.21...v0.3.22) (2026-09-04)


### Fixed

* **observability:** bump opensearch/otel-collector/tempo, fix deploy-blocking + test bugs ([#1741](https://github.com/paruff/fawkes/issues/1741)) ([cfb400b](https://github.com/paruff/fawkes/commit/cfb400be8d2c7c5170581b0d054e37406ad4c46b))

## [0.3.21](https://github.com/paruff/fawkes/compare/v0.3.20...v0.3.21) (2026-09-04)


### Fixed

* **terraform:** require explicit kms_key_arn in the unused aws/eks module ([#1739](https://github.com/paruff/fawkes/issues/1739)) ([413fbbc](https://github.com/paruff/fawkes/commit/413fbbc4a3e59019789e3ec6d3812efb2dfac978))

## [0.3.20](https://github.com/paruff/fawkes/compare/v0.3.19...v0.3.20) (2026-09-04)


### Fixed

* **observability:** fix 3 BDD bugs, bump ingress-nginx, verify chart versions ([#1734](https://github.com/paruff/fawkes/issues/1734)) ([64ae710](https://github.com/paruff/fawkes/commit/64ae710ba886f6b6577f9811a2d81bbcd91de2f1))

## [0.3.19](https://github.com/paruff/fawkes/compare/v0.3.18...v0.3.19) (2026-09-04)


### Fixed

* **test:** register missing pytest-bdd markers, fix doubled feature path ([#1732](https://github.com/paruff/fawkes/issues/1732)) ([7bb6bb9](https://github.com/paruff/fawkes/commit/7bb6bb9a0dafee54fe5b0bc130aa6aa40896e417))

## [0.3.18](https://github.com/paruff/fawkes/compare/v0.3.17...v0.3.18) (2026-09-04)


### Fixed

* **terraform:** stop overriding EKS module's safe encryption default ([#1730](https://github.com/paruff/fawkes/issues/1730)) ([20af291](https://github.com/paruff/fawkes/commit/20af291f60143d2971a7e1198d4caf48ed53e7b0))

## [0.3.17](https://github.com/paruff/fawkes/compare/v0.3.16...v0.3.17) (2026-09-04)


### Fixed

* **security:** add missing writable /tmp to readOnlyRootFilesystem containers ([#1728](https://github.com/paruff/fawkes/issues/1728)) ([9565eb0](https://github.com/paruff/fawkes/commit/9565eb0f54622e741f5ff72d778f1fd0fc0a6203))
* **security:** unblock tracer-bullet's CI Trivy gate ([#1727](https://github.com/paruff/fawkes/issues/1727)) ([aedd800](https://github.com/paruff/fawkes/commit/aedd800af66775bf994b518bb25c29095eced5ca))

## [0.3.16](https://github.com/paruff/fawkes/compare/v0.3.15...v0.3.16) (2026-09-04)


### Fixed

* **security:** add signature verification to friction-bot slash commands ([#1720](https://github.com/paruff/fawkes/issues/1720)) ([c233e9f](https://github.com/paruff/fawkes/commit/c233e9f593997d7997a5795ecbb7671249f3d2ce))


### Docs

* correct DEPLOYMENT_STRATEGY.md gaps table against verified reality ([#1724](https://github.com/paruff/fawkes/issues/1724)) ([a92c4d4](https://github.com/paruff/fawkes/commit/a92c4d4e3f9ecfe461eecb7b6f2beb586f694f59))

## [0.3.15](https://github.com/paruff/fawkes/compare/v0.3.14...v0.3.15) (2026-09-04)


### Fixed

* **deps:** bump postcss to 8.5.28 for three CVEs ([#1718](https://github.com/paruff/fawkes/issues/1718)) ([46416a7](https://github.com/paruff/fawkes/commit/46416a70a0eec2dd1f5dbd352ec68bd2a0830742))
* **deps:** upgrade storybook to 8 and vite to patched 6.4.3 ([#1717](https://github.com/paruff/fawkes/issues/1717)) ([fdca077](https://github.com/paruff/fawkes/commit/fdca077310b0744a3ef86737feb63c6419a197b7))

## [0.3.14](https://github.com/paruff/fawkes/compare/v0.3.13...v0.3.14) (2026-09-04)


### Fixed

* **deps:** add safe npm overrides for design-system vulns ([#1714](https://github.com/paruff/fawkes/issues/1714)) ([45aa393](https://github.com/paruff/fawkes/commit/45aa39333b3fd94adc3b75b70e31b7e5b646f4fd))

## [0.3.13](https://github.com/paruff/fawkes/compare/v0.3.12...v0.3.13) (2026-09-04)


### Fixed

* **terraform:** require authorized IP ranges for AKS API server ([#1712](https://github.com/paruff/fawkes/issues/1712)) ([23a7e3e](https://github.com/paruff/fawkes/commit/23a7e3eb5951c8d99381c8e21fa8862150aed330))

## [0.3.12](https://github.com/paruff/fawkes/compare/v0.3.11...v0.3.12) (2026-09-04)


### Fixed

* **security:** read-only rootfs for unleash containers ([#1708](https://github.com/paruff/fawkes/issues/1708)) ([e47dc64](https://github.com/paruff/fawkes/commit/e47dc6456f3ec41ded22b97f82728a10e621fb21))
* **terraform:** default SNS topic encryption to AWS-managed key ([#1710](https://github.com/paruff/fawkes/issues/1710)) ([034a40e](https://github.com/paruff/fawkes/commit/034a40eea084bb6fbe42e966bec40c4fba8675c5))

## [0.3.11](https://github.com/paruff/fawkes/compare/v0.3.10...v0.3.11) (2026-09-04)


### Fixed

* **security:** read-only rootfs for plausible containers ([#1707](https://github.com/paruff/fawkes/issues/1707)) ([b10400f](https://github.com/paruff/fawkes/commit/b10400f0199adc4ae53a140329ab5b6fd9219746))
* **terraform:** sync lock and document EKS node SG egress decision ([#1706](https://github.com/paruff/fawkes/issues/1706)) ([002f91f](https://github.com/paruff/fawkes/commit/002f91fcedab9d2f0e3b301858132569531dd8f2))

## [0.3.10](https://github.com/paruff/fawkes/compare/v0.3.9...v0.3.10) (2026-09-04)


### Fixed

* **security:** read-only rootfs for vsm-service deployment ([#1703](https://github.com/paruff/fawkes/issues/1703)) ([dc23cb1](https://github.com/paruff/fawkes/commit/dc23cb1535c18f33783f7edfe70de9ae98fb03eb))


### Docs

* **backlog:** mark resolved follow-up [#1692](https://github.com/paruff/fawkes/issues/1692) in flagged table ([#1704](https://github.com/paruff/fawkes/issues/1704)) ([227d395](https://github.com/paruff/fawkes/commit/227d3953f366efa12adbc60e83e113a812533daa))

## [0.3.9](https://github.com/paruff/fawkes/compare/v0.3.8...v0.3.9) (2026-09-04)


### Added

* **a11y:** note pending metrics in accessibility dashboard ([#1700](https://github.com/paruff/fawkes/issues/1700)) ([e50505a](https://github.com/paruff/fawkes/commit/e50505abe99e110492a7da6eeedea4265f50975b))


### Fixed

* **extensions:** repair data-quality kustomization and ArgoCD path ([#1699](https://github.com/paruff/fawkes/issues/1699)) ([c1bd146](https://github.com/paruff/fawkes/commit/c1bd1461c2875607334168addd680e459e8f1434))
* **terraform:** reject postgres firewall rules without public access ([#1701](https://github.com/paruff/fawkes/issues/1701)) ([15dbed0](https://github.com/paruff/fawkes/commit/15dbed0412ee7f7c6c9d37fbec153cc1395560b1))

## [0.3.8](https://github.com/paruff/fawkes/compare/v0.3.7...v0.3.8) (2026-09-04)


### Fixed

* **terraform:** default EKS endpoint_public_access to false ([#1697](https://github.com/paruff/fawkes/issues/1697)) ([5356bd0](https://github.com/paruff/fawkes/commit/5356bd0b38caaa8d8ffbc3f76595873a93d8fb5d))


### Docs

* **backlog:** fix orphan anchor and track flagged follow-ups ([#1696](https://github.com/paruff/fawkes/issues/1696)) ([583d63a](https://github.com/paruff/fawkes/commit/583d63a34633d97cb022dd8450aa8f499854a484))

## [0.3.7](https://github.com/paruff/fawkes/compare/v0.3.6...v0.3.7) (2026-09-04)


### Added

* **a11y:** provision accessibility dashboard and document program ([#1690](https://github.com/paruff/fawkes/issues/1690)) ([0d003fb](https://github.com/paruff/fawkes/commit/0d003fb2268cd5e62998169e926d5957b6635293))

## [0.3.6](https://github.com/paruff/fawkes/compare/v0.3.5...v0.3.6) (2026-09-04)


### Fixed

* **security:** stop leaking exception text in HTTP responses ([#1688](https://github.com/paruff/fawkes/issues/1688)) ([016c935](https://github.com/paruff/fawkes/commit/016c93532752dcb4a629f9dff9d125812d15a591))

## [0.3.5](https://github.com/paruff/fawkes/compare/v0.3.4...v0.3.5) (2026-09-04)


### Fixed

* **security:** harden securityContext on extensions workloads ([#1686](https://github.com/paruff/fawkes/issues/1686)) ([941a833](https://github.com/paruff/fawkes/commit/941a83373fda68e041cfb8777f0b40d51c16686d))

## [0.3.4](https://github.com/paruff/fawkes/compare/v0.3.3...v0.3.4) (2026-09-04)


### Fixed

* **security:** run mcp-k8s-server and Dockerfile.secure as non-root ([#1685](https://github.com/paruff/fawkes/issues/1685)) ([feaaa61](https://github.com/paruff/fawkes/commit/feaaa614685fd4def81cfb658dced435406bf1c5))
* **security:** scope Spring Boot actuator exposure ([#1683](https://github.com/paruff/fawkes/issues/1683)) ([7a0b4cf](https://github.com/paruff/fawkes/commit/7a0b4cfa086f2441a183dd3d371f757a3c5ee8f0))

## [0.3.3](https://github.com/paruff/fawkes/compare/v0.3.2...v0.3.3) (2026-09-04)


### Fixed

* **terraform:** default VPC public IPs and DB firewall to private ([#1681](https://github.com/paruff/fawkes/issues/1681)) ([422b14c](https://github.com/paruff/fawkes/commit/422b14c5fbe465777010180827546e38bf9bf163))

## [0.3.2](https://github.com/paruff/fawkes/compare/v0.3.1...v0.3.2) (2026-09-02)


### Fixed

* Dependencies already patched; alerts should close. ([#1676](https://github.com/paruff/fawkes/issues/1676)) ([7850715](https://github.com/paruff/fawkes/commit/78507153d29e3d3713f6f2669eb454d244db793b))

## [0.3.1](https://github.com/paruff/fawkes/compare/v0.3.0...v0.3.1) (2026-09-02)


### Added

* add GitOps lifecycle gates to fawkes ([6232d9b](https://github.com/paruff/fawkes/commit/6232d9ba585e67385b87d8d233687f0dd4124b9a))
* add GitOps lifecycle gates to fawkes ([5d41b8b](https://github.com/paruff/fawkes/commit/5d41b8bc4bf75fb85d4837579639edb871f0934e))
* **agents:** add security-agent (Claude Sonnet 4.6, 1×) ([d73e16e](https://github.com/paruff/fawkes/commit/d73e16eb346737f56db5c86bbceef32661585004))
* **agents:** add security-agent.agent.md (Claude Sonnet 4.6, 1x) ([41fc31e](https://github.com/paruff/fawkes/commit/41fc31ee5fae38aacd78d53b8e716b2046488808))
* **agents:** add workflow-focused agents and skills ([17f0fe3](https://github.com/paruff/fawkes/commit/17f0fe3700b9e39a023fbf05949717e8ad457fde))
* **ci:** add release-please automated release proposals ([#1674](https://github.com/paruff/fawkes/issues/1674)) ([63115f6](https://github.com/paruff/fawkes/commit/63115f6e713df688ca177f659dcd204b8236879e))
* **ci:** route [security]/[feature] tags to nvidia nemotron-3 ([a9fc3b5](https://github.com/paruff/fawkes/commit/a9fc3b53532e93acf96d6ff971ca205b74f0e103))
* **ci:** route [security]/[feature] tags to NVIDIA nemotron-3 ([50e0b78](https://github.com/paruff/fawkes/commit/50e0b78253778c41a34cc69e49c2b385cd50eb30))
* **dcp+security:** Backstage template discovery + advisory security scanning ([f92a299](https://github.com/paruff/fawkes/commit/f92a299e52453bad9bdb16f7cf39c1199f4fde20))
* **dcp:** Phase 3b — DORA metrics exporter, AI amplification rules, SPACE aliases ([278a759](https://github.com/paruff/fawkes/commit/278a759ec27e0bc20d6c7e9d60822c0ad891f004))
* **dcp:** wire all 23 services into Backstage catalog + shared template fragments ([0645634](https://github.com/paruff/fawkes/commit/06456347c847db30f3e3d493ed42c31858f6be1f))
* **dev-exp:** make dev-up — single-command local platform with 5 core components ([0535f3b](https://github.com/paruff/fawkes/commit/0535f3b69cc3da1574e4bf01188eac7f684b2b96))
* **dev-exp:** make dev-up — single-command local platform with 5 core components ([95df5c5](https://github.com/paruff/fawkes/commit/95df5c56acf8e8eaac893a204fe6a1a2d75c96c7))
* **dojo:** implement end-to-end runnable White Belt Module 1 lab ([657abb7](https://github.com/paruff/fawkes/commit/657abb77f19f022bc7893efbdc541eb2f382f42e))
* **dojo:** implement White Belt Module 1 lab with validate script and Makefile target ([118fd84](https://github.com/paruff/fawkes/commit/118fd847156fefd464cbf7eab7377fce0251be55))
* **dora-metrics:** deploy DORA metrics exporter via ArgoCD ([f86aeee](https://github.com/paruff/fawkes/commit/f86aeee0b11c3bfa4f40683b7311861de3c409a5))
* **dora-metrics:** deploy the DORA metrics exporter via ArgoCD ([cc8ac6e](https://github.com/paruff/fawkes/commit/cc8ac6e063b997a37b3d8151a0d9e6c238870804))
* **extensions:** move Data/AI layer from platform/ and services/ to extensions/ ([7dc4696](https://github.com/paruff/fawkes/commit/7dc4696bdcc9148678840a2865f0f725ad17733f))
* **infra:** add IRSA support to eks-namespace module, wire for tracer-bullet ([3723b3d](https://github.com/paruff/fawkes/commit/3723b3d7e30d7847d66a89a30f8effd06370636b))
* **infra:** add Terraform bootstrap for state S3+DynamoDB backend ([55871ac](https://github.com/paruff/fawkes/commit/55871acf14890ec73e4f1e7c235b123711174af3))
* **opencode:** add agent skills and project config for free-tier models ([db65444](https://github.com/paruff/fawkes/commit/db654440c9a87c5149916c8764f6cb20a7a899ec))
* **wave-0:** infra prerequisites — remote state, sealed secrets, BATS, DORA ([1658f65](https://github.com/paruff/fawkes/commit/1658f65e439e446fd0d9ba930d0d271865bb711b))
* **wave-1:** tracer bullet — full end-to-end deployment pipeline ([17d8cbb](https://github.com/paruff/fawkes/commit/17d8cbbe90eacef84bd49f5a74cdfb77fa3adac3))
* **wave-2:** observable golden path — OTEL tracing, structured logs, BDD, E2E ([a0681df](https://github.com/paruff/fawkes/commit/a0681df6c75d6c12743654a7ce63efbd1063356b))


### Fixed

* Added python-patch group to dependabot.yml for weekly patch PRs ([#1654](https://github.com/paruff/fawkes/issues/1654)) ([7ad9168](https://github.com/paruff/fawkes/commit/7ad91688504997455d4af4e1a9f1f675094b2aeb))
* Added securityContext to all 4 Penpot deployments ([#1665](https://github.com/paruff/fawkes/issues/1665)) ([09fc629](https://github.com/paruff/fawkes/commit/09fc629b10274d435fb5012c0fff78dbc36c036a))
* **agents:** correct YAML frontmatter delimiters and indentation in gpt41-default, infra-gitops, test-engineer agent files ([087244b](https://github.com/paruff/fawkes/commit/087244bd21c9d2355869db685a7e7de0eca06464))
* **agents:** repair YAML frontmatter in 3 agent files missing from Copilot sessions dropdown ([0c4414c](https://github.com/paruff/fawkes/commit/0c4414cf036fc6e3a9a78a00b0ecb8e5a0b76d7a))
* apply Prettier formatting to markdown files failing CI ([844065d](https://github.com/paruff/fawkes/commit/844065d48b4ba3c4b57c4a25c987bbfdc6cf2772))
* apply shfmt formatting to dev-up.sh and dev-status.sh ([d916d54](https://github.com/paruff/fawkes/commit/d916d54bd4f1056db64be8d62b41fadf0a58c6b5))
* bulk resolve 275 flake8 issues across entire codebase ([574822d](https://github.com/paruff/fawkes/commit/574822dceb2fe508179a8ed80a84aa3069c92a19))
* **ci:** add -upgrade to terraform init to resolve lock file staleness ([b8e7b04](https://github.com/paruff/fawkes/commit/b8e7b044655d6469b4c041290eda44085cbdcdcf))
* **ci:** add coreutils for BATS timeout command ([458b8fc](https://github.com/paruff/fawkes/commit/458b8fc868ba6e53c938e2cce8ab4c454e05a323))
* **ci:** address review findings — pin action versions, improve change detection ([4e3b14e](https://github.com/paruff/fawkes/commit/4e3b14eca630fd13883953a26461c6f16c45020c))
* **ci:** bump go-version 1.24 -&gt; 1.25 to match terratest go.mod requirement ([ca4e8f6](https://github.com/paruff/fawkes/commit/ca4e8f64a9da32318a1a68da2858b8fbe508ef99))
* **ci:** call main-ci-guard reusable workflow at job level ([272d3c5](https://github.com/paruff/fawkes/commit/272d3c51d9e46f51c7d1e83f0e2493defbdc3bb6))
* **ci:** call main-ci-guard reusable workflow at job level ([e38fddc](https://github.com/paruff/fawkes/commit/e38fddc71758218390a28606afec829f6dda16ac))
* **ci:** clear stale git auth header before normalize-step push ([#1641](https://github.com/paruff/fawkes/issues/1641)) ([2994e64](https://github.com/paruff/fawkes/commit/2994e645f29104aa4827f592aca4c492b84f96ef))
* **ci:** consolidate pre-commit hooks, replace black/flake8 with ruff, unify secret scanning ([824573b](https://github.com/paruff/fawkes/commit/824573b79b17b6c1473b6c7803151802ed297f03))
* **ci:** correct nemotron pricing note, fix terraform-install hang ([7cfe765](https://github.com/paruff/fawkes/commit/7cfe765ba4e3129aedd0ed71c16edf3151b2b5b5))
* **ci:** enforce commit convention via pre-commit commit-msg hook ([06e3ef9](https://github.com/paruff/fawkes/commit/06e3ef9278480360dffaee596911e251a6d05e22))
* **ci:** enforce commit convention via pre-commit commit-msg hook ([aeb58ee](https://github.com/paruff/fawkes/commit/aeb58ee72b1d9561b47480a60363b52960af0edb))
* **ci:** fix model provider id, wire up NVIDIA/Gemini, add skills ([3ae251e](https://github.com/paruff/fawkes/commit/3ae251e619fc490c12ee491a234b510ab8b2137a))
* **ci:** fix NVIDIA nemotron model id, doubled prefix required ([70d14c3](https://github.com/paruff/fawkes/commit/70d14c30f9e78e5508b6c072c1115d61efdd8daf))
* **ci:** fix NVIDIA nemotron model id, doubled prefix required ([fa31b01](https://github.com/paruff/fawkes/commit/fa31b0123fb15ad512217b2eeb34bc303021502f))
* **ci:** format markdown and template files for pre-commit base hooks ([20161aa](https://github.com/paruff/fawkes/commit/20161aa5d75a9973cc45a1775b88818ab944c877))
* **ci:** grant actions:read permission for Main CI Guard reusable workflow ([08c2141](https://github.com/paruff/fawkes/commit/08c2141cdb46697b45321b44a750762f54f5e81b))
* **ci:** grant actions:read permission for Main CI Guard reusable workflow ([041c442](https://github.com/paruff/fawkes/commit/041c442fb39cb894ce3fa7d50f7728fdc6b4f31f))
* **ci:** grant actions:write for opencode CLI caching ([17e4ec5](https://github.com/paruff/fawkes/commit/17e4ec5887c64e2d9c8404b36e48ad5f8b4f3630))
* **ci:** grant actions:write so opencode CLI cache can save ([4f29599](https://github.com/paruff/fawkes/commit/4f2959960704b286e2986e40a047437fa97181bc))
* **ci:** install terraform/tflint, fix ask-permission hang ([ff84ebb](https://github.com/paruff/fawkes/commit/ff84ebbebfbdb89defbad423f8430f95fd7e1c5d))
* **ci:** make pre-commit checks PR-scoped and non-mutating ([a7cfdb4](https://github.com/paruff/fawkes/commit/a7cfdb4b2811c384e749cf7ebc5d316c3467abec))
* **ci:** mechanically normalize non-compliant opencode commits ([4aa1762](https://github.com/paruff/fawkes/commit/4aa17624dd3ce5836119671822241f41c582a6d3))
* **ci:** mechanically normalize non-compliant opencode commits ([0b1d05e](https://github.com/paruff/fawkes/commit/0b1d05ee818be8134c3111549967f6834240e20e))
* **ci:** pass needs context via env, not invalid inputs.x ref ([#1666](https://github.com/paruff/fawkes/issues/1666)) ([472fbf5](https://github.com/paruff/fawkes/commit/472fbf5426e6e83cca06921feeadaebdfea4c8c5))
* **ci:** pin mcp-k8s-server image to python 3.13.14 ([5565eff](https://github.com/paruff/fawkes/commit/5565eff148a6de9380632d888c4883d4263712ad))
* **ci:** raise opencode timeout, update actions, fix git identity ([30ef61e](https://github.com/paruff/fawkes/commit/30ef61e9e24429a3338d46d8ac022cfa5c3fee80))
* **ci:** raise opencode timeout, update pinned actions ([578831e](https://github.com/paruff/fawkes/commit/578831e0ae3cf7a47d26267e6b45ddc6b33e629c))
* **ci:** reduce Terraform cache to global plugin cache only to prevent disk exhaustion ([bab4896](https://github.com/paruff/fawkes/commit/bab4896bcad68c50167294cc736e0bb99faf7815))
* **ci:** remove commit-msg hook, add live model resolver ([#1630](https://github.com/paruff/fawkes/issues/1630)) ([68f8894](https://github.com/paruff/fawkes/commit/68f8894240f93688033f50c555a2294d3ac17f05))
* **ci:** remove duplicate `main-ci-guard` job key in main-ci-guard.yml ([f171bff](https://github.com/paruff/fawkes/commit/f171bffd2f7a2c64be2a1c7a89da2a0ee9e93649))
* **ci:** remove duplicate linters, merge python jobs, align coverage gate ([94ce549](https://github.com/paruff/fawkes/commit/94ce549ba3a076b24bff53b66aa794f916e1913c))
* **ci:** remove duplicate main-ci-guard job key in main-ci-guard.yml ([c78b8da](https://github.com/paruff/fawkes/commit/c78b8dac7ad2878addd0c4796d3897ba22d94593))
* **ci:** remove if:always() from security-scanning job to prevent wasted CI minutes on cancellation ([074718b](https://github.com/paruff/fawkes/commit/074718b5a331e28688ef2a8d48a9d99094ee7cf9))
* **ci:** remove orphaned lines from security-scanning job conversion ([8b1a9eb](https://github.com/paruff/fawkes/commit/8b1a9ebc218beba9ce3bafabe30332767ee44db5))
* **ci:** remove Prettier from pre-commit and CI pipeline ([cfb09c0](https://github.com/paruff/fawkes/commit/cfb09c08156ac2b5d8a3df33f35c25ea1f77e082))
* **ci:** remove Prettier from pre-commit and CI pipeline ([28900e7](https://github.com/paruff/fawkes/commit/28900e7cffca2fe505fcc68cb906fa11eb39361b))
* **ci:** remove trailing blank lines from observability terraform files ([b5596ae](https://github.com/paruff/fawkes/commit/b5596aed39c353a9440d242299dd0e27bdba5e6e))
* **ci:** repair broken opencode.yml workflow ([7a80317](https://github.com/paruff/fawkes/commit/7a803173462537db8b1caf4011988ecbae7e46b6))
* **ci:** repair broken opencode.yml workflow ([b5eaf1c](https://github.com/paruff/fawkes/commit/b5eaf1c9e4edbc19bb1fd86f1bcb3ff0ee23e0d7))
* **ci:** repair pre-existing CI failures on main ([3277f8c](https://github.com/paruff/fawkes/commit/3277f8c405b0b777446242c08caf68a4cb36724d))
* **ci:** repair pre-existing CI failures on main ([a60ac3a](https://github.com/paruff/fawkes/commit/a60ac3a8cf1b61846f4cc07e1a7a13a2164ecb2e))
* **ci:** repair reusable-lint.yml indentation and pin valid Trivy tag ([abbdcb6](https://github.com/paruff/fawkes/commit/abbdcb65e56384d086015ff4d4f31d9cc9c95739))
* **ci:** repair reusable-lint.yml indentation and pin valid Trivy tag ([9ba8076](https://github.com/paruff/fawkes/commit/9ba807675fbbfb157b4f1fabf9400e65f2c0fe4c))
* **ci:** resolve 7 failing checks in code-quality workflow ([cd29221](https://github.com/paruff/fawkes/commit/cd2922129497164ec348a2fa152cb84180a234bd))
* **ci:** resolve a11y workflow failures — Lighthouse URL, needs context, JUnit reporter ([c8d9254](https://github.com/paruff/fawkes/commit/c8d925463a5919081932c6ca2f09281b6761936c))
* **ci:** resolve all 5 failing workflow checks ([0601f9c](https://github.com/paruff/fawkes/commit/0601f9c4d42a1ffb7ec4b73cb37db25b4ddd2faa))
* **ci:** resolve CodeQL XSS, Trivy root-user, and missing tfsec binary ([12af4ed](https://github.com/paruff/fawkes/commit/12af4ed9aa768cbebd406c15b53837b16df95822))
* **ci:** resolve pre-existing CI failures across pre-commit and code-quality workflows ([5f9e05c](https://github.com/paruff/fawkes/commit/5f9e05c13228d2d3fc367895973f867f7928f741)), closes [#1442](https://github.com/paruff/fawkes/issues/1442)
* **ci:** resolve systemic CI failures across dependabot PRs ([f7f5cf9](https://github.com/paruff/fawkes/commit/f7f5cf94cea2e3260fbb9b4b24bdb64a757985cc))
* **ci:** resolve systemic CI failures across dependabot PRs ([#1481](https://github.com/paruff/fawkes/issues/1481)-[#1490](https://github.com/paruff/fawkes/issues/1490)) ([a2339be](https://github.com/paruff/fawkes/commit/a2339befcec156c2cc373c3b2c9260c319854c7b))
* **ci:** restore contents/actions permissions to main-ci-guard job ([7d45d6d](https://github.com/paruff/fawkes/commit/7d45d6dadf80bbd8bca825753350c1c999757f71))
* **ci:** restore contents/actions permissions to main-ci-guard job ([9bd8876](https://github.com/paruff/fawkes/commit/9bd8876d53d71c050676b16da0a6b562a20f0bc8))
* **ci:** restore local reusable-security-scanning.yml ([be97315](https://github.com/paruff/fawkes/commit/be97315ef31c5c32de7dd67c8169b41f5d060a0c))
* **ci:** restore local reusable-security-scanning.yml ([641f164](https://github.com/paruff/fawkes/commit/641f1644bd77a60ce259519eb7f3c3cae0bd578e))
* **ci:** scope pre-commit language and terraform checks ([0ce483b](https://github.com/paruff/fawkes/commit/0ce483b8cc82b81077967bc2eed621d160d07936))
* **ci:** setup-trivy version needs v-prefixed GitHub release tag ([e841ba2](https://github.com/paruff/fawkes/commit/e841ba2608f53f714dd68d38a424963de2b8b66d))
* **ci:** split pre-commit workflow into 4 parallel layer jobs ([0535d47](https://github.com/paruff/fawkes/commit/0535d47b0981b30a9c060e37698e4e3379da8933))
* **ci:** stabilize PR workflows and pin trivy action ([3c208f4](https://github.com/paruff/fawkes/commit/3c208f42be41a8eb522ca4614dda3abee2a9bf8b))
* **ci:** standardize Go toolchain to 1.26 across all workflows ([e7e5117](https://github.com/paruff/fawkes/commit/e7e511790ac3b5417e02d4882ab6b0f41a118282))
* **ci:** stop opencode workflow self-retriggering ([05a682f](https://github.com/paruff/fawkes/commit/05a682f789639a87e6391999af57f9c364bafde1))
* **ci:** stop opencode workflow self-retriggering on its own comments ([251a325](https://github.com/paruff/fawkes/commit/251a32529706f9d011f13cb3cd1d401a88278f6a))
* **ci:** swap paid nemotron-3-ultra for free nvidia qwen3 coder ([e517d54](https://github.com/paruff/fawkes/commit/e517d54da6bd33dfdc3e9046dbd86ffbcdb4e812))
* **ci:** tune pre-commit config, ruff rules, and workflow splitting ([8aa08c4](https://github.com/paruff/fawkes/commit/8aa08c4201846b09c83ab9f9e2f7b88fb2ff4c5f))
* **deps:** Fix minimatch ESM/CJS incompatibility breaking Jest coverage ([efb522a](https://github.com/paruff/fawkes/commit/efb522aa0fcebd1da827f5e7fbc91847b776deae))
* **deps:** pin all Python dependencies to exact versions (==) ([e448dcd](https://github.com/paruff/fawkes/commit/e448dcd654a5b3b5fea82bdf52a22621aaa8aa36))
* **deps:** pin all Python dependencies to exact versions (==) — ADR-034 ([a5c5aa1](https://github.com/paruff/fawkes/commit/a5c5aa1b765ba02e81762a9dd14a40572a291f42))
* **deps:** upgrade google.golang.org/api to v0.285.0 for grpc compat ([c1f4269](https://github.com/paruff/fawkes/commit/c1f426958dc903b94c72a1d3c3589b5fe1e45119))
* **deps:** upgrade google.golang.org/api to v0.285.0 for grpc v1.79.3+ compat ([2eaa4b3](https://github.com/paruff/fawkes/commit/2eaa4b368ab2f40bbc82908d97bac74f29a6940c))
* **design-system:** bump npm overrides to close 13 Dependabot alerts ([9ca0478](https://github.com/paruff/fawkes/commit/9ca047802e20200813e8277272fd209bedef75ee))
* **design-system:** bump npm overrides to close 13 Dependabot alerts ([60e0c2d](https://github.com/paruff/fawkes/commit/60e0c2d1637817b3b47b3063edc4636fe4068715))
* **design-system:** bump npm overrides to close 13 Dependabot alerts ([704c25f](https://github.com/paruff/fawkes/commit/704c25fdc16f81c585cca6ac8b2ac4ab83317863))
* **design-system:** refine npm override bump (smaller diff, minimal floors) ([0e08b74](https://github.com/paruff/fawkes/commit/0e08b74f92ac1f78e2f0c485a11688de44e9894a))
* **design-system:** resolve accessibility CI failures ([b828202](https://github.com/paruff/fawkes/commit/b828202eaf18f20d86df47a9ff9313f3f3c1d623))
* **design-system:** resolve minimatch ESM/CJS incompatibility breaking Jest coverage ([7a4eb1b](https://github.com/paruff/fawkes/commit/7a4eb1b9845be0cf5c34780bec3432c2cd7ae19f))
* **dev-exp:** fix box alignment in dev-status and wait on podinfo deployment ([c7c3560](https://github.com/paruff/fawkes/commit/c7c35602dcd3b90c97898fbbce535e23537d5d8f))
* **dev-status:** improve error message for cluster check ([2b85e91](https://github.com/paruff/fawkes/commit/2b85e916c0ff391982dbf6a5c6dc7aeaf4fba6c7))
* **dev-status:** resolve merge conflict with main — align style with 3e0d6ddb ([f98e37c](https://github.com/paruff/fawkes/commit/f98e37c56a8813e6c43a87dc0153e56a21ba9c54))
* disable noisy terraform_standard_module_structure TFLint rule ([683c77b](https://github.com/paruff/fawkes/commit/683c77bad9af8fb8dfa7b473e5e0f83015a993f3))
* **dora-metrics:** add tests/__init__.py to fix CI test collection ([fc34879](https://github.com/paruff/fawkes/commit/fc34879c01ccad30d185b9dbf217aa218ecc3f35))
* **dora-metrics:** fix Dockerfile layout and asyncio scrape crash ([77a20e7](https://github.com/paruff/fawkes/commit/77a20e7faf43be253d79a66235682dcb65439d51))
* **dora-metrics:** fix Dockerfile layout bug and asyncio scrape crash (found via live cluster test) ([e875568](https://github.com/paruff/fawkes/commit/e8755686a2e4e03c0d1a156115764dab91369b17))
* **dora-metrics:** resolve Trivy scan failures blocking Build & Push on main ([84c784a](https://github.com/paruff/fawkes/commit/84c784a42b8e562cb2abb1b9579e8cd212c59af1))
* **dora-metrics:** resolve Trivy scan failures blocking Build & Push on main ([fa94a80](https://github.com/paruff/fawkes/commit/fa94a80c635c039f88c049c51f845d3098aaab55))
* eliminate JS-context XSS sink in nasa-tlx page ([7782c2f](https://github.com/paruff/fawkes/commit/7782c2f7340dcd4e7a1aab067977cad0054eb820))
* Fixed all Dependabot alerts via dependency bumps + overrides ([#1657](https://github.com/paruff/fawkes/issues/1657)) ([7f6e573](https://github.com/paruff/fawkes/commit/7f6e57332665ba1d8079a6d71e46b07028de4ae3))
* Fixed sealed-secrets ArgoCD app: OCI source, v2.19.3 ([#1653](https://github.com/paruff/fawkes/issues/1653)) ([9d57a13](https://github.com/paruff/fawkes/commit/9d57a138e039767fbe16662821776037591c14a5))
* **gitops:** update pre-commit template for repo compatibility ([24b2740](https://github.com/paruff/fawkes/commit/24b2740b056373c74a7d08523486dbb4c3802374))
* **gitops:** update pre-commit template for repo compatibility ([9d4ce91](https://github.com/paruff/fawkes/commit/9d4ce91ab18ab550563445d4646c050cc2b4abc3))
* **infra:** add node_provisioning_profile to azure/aks module ([4ab7fb5](https://github.com/paruff/fawkes/commit/4ab7fb55fd156c26e6efaa2a3405f0a06a6e413b))
* **infra:** add node_provisioning_profile to azure/kubernetes-cluster module ([ef4f952](https://github.com/paruff/fawkes/commit/ef4f952ee8c5eab332cb4b30ae6c061b1633e900))
* **infra:** add node_provisioning_profile to azure/kubernetes-cluster module ([2ba730e](https://github.com/paruff/fawkes/commit/2ba730ead5087d3ef1f79c3449da755ea660c0e9))
* **infra:** pin azurerm provider below v5 in aks module ([3d58d3d](https://github.com/paruff/fawkes/commit/3d58d3d5f9357feff24c1ffd205a762e75eea6ec))
* **infra:** pin azurerm provider below v5 in aks module ([8feeeca](https://github.com/paruff/fawkes/commit/8feeeca603f2002f28c3b90934de1eefe9a99b7f))
* **infra:** pin azurerm provider version and fix vnet module for v5 ([b01da8e](https://github.com/paruff/fawkes/commit/b01da8e86643163d9fcc38b9ff44cf9876b11949))
* **infra:** remove unrestricted SSH ingress defaults from AWS security groups ([#1650](https://github.com/paruff/fawkes/issues/1650)) ([29774ef](https://github.com/paruff/fawkes/commit/29774efc9ead312a488315c9b3c4a4d4bc06c134)), closes [#1588](https://github.com/paruff/fawkes/issues/1588)
* **infra:** remove unused tags variable from eks-namespace module ([a93e723](https://github.com/paruff/fawkes/commit/a93e72391c744ac2430e2901d9109da45714990f))
* **infra:** remove wildcard source_address_prefix from azure/vnet example ([650085f](https://github.com/paruff/fawkes/commit/650085fb92d4a0ea241fbb22ac635541f0d5cc93))
* **infra:** remove wildcard source_address_prefix from azure/vnet example ([759db03](https://github.com/paruff/fawkes/commit/759db030338c6fb5250258d63502c7ba29dd9525))
* **infra:** restore azure/database and azure/vnet modules ([a4cd986](https://github.com/paruff/fawkes/commit/a4cd986071c0e87de978478ab27c91852777df90))
* **infra:** tighten insecure SG/endpoint defaults in unused AWS modules ([41992d8](https://github.com/paruff/fawkes/commit/41992d8a86ae6533f14b2b44c58188662f372a00))
* **infra:** tighten insecure SG/endpoint defaults in unused AWS modules ([54b1302](https://github.com/paruff/fawkes/commit/54b13023f9895ee9856c53c7050c0b6919ab195b))
* **infra:** update Azure resources for azurerm v5.0 breaking schema changes ([2370616](https://github.com/paruff/fawkes/commit/237061625dfaaafef2a42de84da68e4f0a6e0b80))
* **infra:** update Azure resources for azurerm v5.0 breaking schema changes ([ec91f83](https://github.com/paruff/fawkes/commit/ec91f839f4562ae93f02887e0bfc5e3445270a10))
* **infra:** upgrade AWS provider lock to 6.49.0 — resolves version constraint conflict ([e0dc4b1](https://github.com/paruff/fawkes/commit/e0dc4b183914f3c200431920c080fa2d1596df77))
* **lint:** resolve ruff findings and apply ruff-format across services ([13db8f5](https://github.com/paruff/fawkes/commit/13db8f57a2c6e80feee76fac783f3efd59477fb8))
* resolve flake8 and markdownlint issues across test and docs files ([193f1e4](https://github.com/paruff/fawkes/commit/193f1e41ec3ec5289eb3f12b3a2a58bb86a11740))
* resolve last markdownlint MD028 blockquote issues ([49af076](https://github.com/paruff/fawkes/commit/49af076ee4330b83b22a483cb5dd28c9842c68c7))
* resolve pre-commit hook failures across all layers ([0640bd8](https://github.com/paruff/fawkes/commit/0640bd8ddeee826780a735e0362bade5cb9fcafd))
* resolve remaining flake8/markdownlint issues, disable MD036 ([85e41e6](https://github.com/paruff/fawkes/commit/85e41e67eb991e28b118b51ce89c080c28f5cd21))
* restrict CORS wildcard origins and add root CODEOWNERS ([968b271](https://github.com/paruff/fawkes/commit/968b2711777b0595ca25faae3a8b2ac69ae9b19c))
* restrict CORS wildcard origins and add root CODEOWNERS ([5cd11ac](https://github.com/paruff/fawkes/commit/5cd11ac5c9c4b65297bb4197d4add172b3a10d6e))
* **scripts:** apply shfmt formatting to dev-up.sh and dev-status.sh ([b5724cc](https://github.com/paruff/fawkes/commit/b5724cc4e87b923be47a733a5eca36c02c5b894e))
* **security:** add network_rules default-deny to Azure storage accounts ([8da3fa2](https://github.com/paruff/fawkes/commit/8da3fa265b44eb52fb040d7ee22b11511b0e4391))
* **security:** add network_rules default-deny to Azure storage accounts ([78cfb6b](https://github.com/paruff/fawkes/commit/78cfb6bf82f7a52473965976e2bae66df6f11cc8))
* **security:** escape reflected survey token to close XSS ([#1649](https://github.com/paruff/fawkes/issues/1649)) ([82ae0ba](https://github.com/paruff/fawkes/commit/82ae0ba657f8849d2b58adfd464113a14114927f))
* **security:** harden GKE/AKS/EKS Terraform modules ([#1587](https://github.com/paruff/fawkes/issues/1587)) ([cb6fa69](https://github.com/paruff/fawkes/commit/cb6fa699c9fe5e0e4d9157124f60dfc601109642))
* **security:** narrow RBAC secrets over-grants in Vault and DataHub ClusterRoles ([ae1453e](https://github.com/paruff/fawkes/commit/ae1453ec279a261621839cf28d6bcfdd505894ce))
* **security:** narrow RBAC secrets over-grants in Vault and DataHub ClusterRoles ([4a81f1a](https://github.com/paruff/fawkes/commit/4a81f1a5903f96406dd1ff67b7e21535cf3c6e5d))
* **security:** remove committed Harbor DB password from ConfigMaps ([cfd4562](https://github.com/paruff/fawkes/commit/cfd456271bdd85c310115ab7fc783fed55bd850e))
* **security:** resolve 3 critical CVEs ([26a381c](https://github.com/paruff/fawkes/commit/26a381c3617085ecbbbaceedb54a5436cca033b2))
* **security:** resolve 3 critical CVEs — Trivy, Handlebars, gRPC-Go ([62cf214](https://github.com/paruff/fawkes/commit/62cf2143c70b1f1bca2b1fa4cbcf8caf3c9af14f))
* stop reflecting nasa-tlx query params through server-rendered HTML ([a518b3d](https://github.com/paruff/fawkes/commit/a518b3df5fcd71fd1dbe52003c31dfea405631f0))
* **test:** add securityContext to azure-storage-test fixture pods ([824c92b](https://github.com/paruff/fawkes/commit/824c92b4e5211b5c24f00925e41d126f923a1c1f))
* **test:** add securityContext to azure-storage-test fixture pods ([90fe4e1](https://github.com/paruff/fawkes/commit/90fe4e18b39373682b4938dc764b19a5d3205756))
* **tracer-bullet:** wire IRSA role via envsubst, mount SA token ([#1631](https://github.com/paruff/fawkes/issues/1631)) ([8ca840e](https://github.com/paruff/fawkes/commit/8ca840e02d193ef90ba1eb3eb26cb4cf385203e8))
* update audit summaries, test strategy docs, and formatting ([6b95e81](https://github.com/paruff/fawkes/commit/6b95e81e4c60390d9dd4d1f836ec3f454c39eb1c))
* **wave-0:** address review blockers — cross-platform date, gitignore, labels ([3c00528](https://github.com/paruff/fawkes/commit/3c00528a146a658563b23c9979413d2c2a5628a8))
* **wave-1:** address review — Trivy gate, type hints, logging, shebangs ([21eee39](https://github.com/paruff/fawkes/commit/21eee39965c648ab9615e53f5a3ecbc8301e0f4c))
* **wave-2:** address review — labels, OTLP toggle, PromQL, prereqs ([721410a](https://github.com/paruff/fawkes/commit/721410a35141ba83d2bc47a04a7c90e09018b5e2))
* **workflows:** replace ternary operators in reusable-accessibility.yml ([4a27967](https://github.com/paruff/fawkes/commit/4a27967c4b1713c55edb7c2e6252186f5e8cb467))


### Docs

* add build report for design-system npm override bump ([28725c6](https://github.com/paruff/fawkes/commit/28725c6cc825b2ffe2b6352b769284e53c7e3be3))
* add build report for securityContext hardening ([#1583](https://github.com/paruff/fawkes/issues/1583)) ([01ad26d](https://github.com/paruff/fawkes/commit/01ad26df5b867258750d336dcbebf4540d951805))
* add build report for securityContext hardening ([#1584](https://github.com/paruff/fawkes/issues/1584)) ([bd43800](https://github.com/paruff/fawkes/commit/bd438004fd8e736b59c51f2a2d6f278013edc0ad))
* add CI pipeline docs and reusable workflows ([5caaab6](https://github.com/paruff/fawkes/commit/5caaab6b6b90cdfe3549dd010d09c8bc2e27af4d))
* add DEVELOPMENT_WORKFLOW.md — plan/build/review cycle with gemma4:e4b and GitOps branching ([12fb9a7](https://github.com/paruff/fawkes/commit/12fb9a794425b754620be9bc31367fec06dd888b))
* add uFawkes stack ecosystem section ([517e101](https://github.com/paruff/fawkes/commit/517e101edcf5a5db3e6e4d84ecd7d76f9e7d5178))
* **agents:** make test-first explicit, add tdd-workflow skill ([f2d5cf5](https://github.com/paruff/fawkes/commit/f2d5cf5cb7d8cc75bdbb2a8093ec133408d83462))
* **agents:** make test-first explicit, add tdd-workflow skill ([45f0572](https://github.com/paruff/fawkes/commit/45f0572908f1d5ed55dff59828ada7aedc3a361b))
* **agents:** tighten commit-format rule, add opencode skill ([64caeb2](https://github.com/paruff/fawkes/commit/64caeb2d8236e678b47ac7536dc1eb486e5d3d6a))
* **agents:** tighten commit-format rule, add opencode skill ([dae2279](https://github.com/paruff/fawkes/commit/dae22790b169fe78ade7a8fbe9f05afd10a8de8c))
* align AGENTS.md and research docs with DORA/SPACE source material ([2c42fc1](https://github.com/paruff/fawkes/commit/2c42fc18cc00c20bff81534c4357493f3a5d5f67))
* align AGENTS.md and research docs with DORA/SPACE source material ([50a492b](https://github.com/paruff/fawkes/commit/50a492b3cbd91b33ee23faa98f6fd564fa953ba5))
* align README, CHANGELOG, and release process with actual v0.3.0 release ([5919b5b](https://github.com/paruff/fawkes/commit/5919b5bc2fc9b3c99ce53d361d86c2b36ea8edca))
* apply markdownlint formatting fixes ([269b519](https://github.com/paruff/fawkes/commit/269b5191a3a0cc56844bcf38a87b22dd345336c5))
* archive OBE implementation-notes/plan/validation docs ([f08cb8e](https://github.com/paruff/fawkes/commit/f08cb8e714798498f7144dfb6c2447f8334e3026))
* **backlog:** add Jenkins-to-Tekton migration epic, Phase 1 ([#1662](https://github.com/paruff/fawkes/issues/1662)) ([bdff074](https://github.com/paruff/fawkes/commit/bdff074571db3da2d4913d5d6568e56806c2acd4))
* **backlog:** mark 7 completed Wave 0 issues as done ([#1658](https://github.com/paruff/fawkes/issues/1658)) ([b4b8086](https://github.com/paruff/fawkes/commit/b4b80860c2f440c627b653e0f80a8417c410a0c5))
* consolidate AI-generated implementation summaries into docs/implementation-notes/ ([e775604](https://github.com/paruff/fawkes/commit/e775604bde459dfbe115e9770f0b4e7264da7769))
* consolidate docs/ directory (archive OBE docs, fix broken links, ADR status drift) ([3df2eba](https://github.com/paruff/fawkes/commit/3df2ebab76c9ca6c4c6bc95a2bc2631984408901))
* define two-tier deployment model with three explicit getting-started paths ([2d5c4c9](https://github.com/paruff/fawkes/commit/2d5c4c942de7f9f5ac157e26e5034bec1e3cac7f))
* define two-tier deployment model with three getting-started paths ([668e098](https://github.com/paruff/fawkes/commit/668e098687982f340ce50471712d9ad27a1e3250))
* delete zero-reference duplicate/OBE docs ([c4e39f9](https://github.com/paruff/fawkes/commit/c4e39f92a73903c2eb751b328e10a5eecbf63746))
* document never-swallow-exceptions principle in coding standards ([86d23fb](https://github.com/paruff/fawkes/commit/86d23fb5f08aaf2fffcf5e5ec992e4469c4ca3a7))
* document never-swallow-exceptions principle in coding standards ([04a5e36](https://github.com/paruff/fawkes/commit/04a5e3645e843b4dfae3eed9e6636afb89c5bf3e))
* fix GOVERNANCE.md typo and 3 stale ADR status fields ([56b4bc7](https://github.com/paruff/fawkes/commit/56b4bc79a22766fafa33da39da288e62b1fa1499))
* flag stalled CAB formation and snapshot-only ci-pipeline-status ([55163b1](https://github.com/paruff/fawkes/commit/55163b10dcf750f207f824a4191649281c7d0ff4))
* lean AGENTS.md with behavioral guidelines, expand .claudeignore ([1872d91](https://github.com/paruff/fawkes/commit/1872d91d1018728c738b0b0e0deef35432158b2b))
* lean AGENTS.md with behavioral guidelines, expand .claudeignore ([225ec0e](https://github.com/paruff/fawkes/commit/225ec0ea0bfc298024cda0e58d5505ce1a765cff))
* mark dojo repo spin-out complete in ROADMAP ([0a0bb8c](https://github.com/paruff/fawkes/commit/0a0bb8c68ef9422d830af94d15a9702e3ba9787f))
* mark dojo repo spin-out complete in ROADMAP ([2f5847a](https://github.com/paruff/fawkes/commit/2f5847a39e384c83debcb8426d1522481c623e9c))
* move AI-generated summaries to docs/implementation-notes/ ([4a3cee4](https://github.com/paruff/fawkes/commit/4a3cee4ea9dec9d093b07bf49c0463c87c3e6573))
* move dojo curriculum to uFawkesDojo repo ([a120a17](https://github.com/paruff/fawkes/commit/a120a17a00787ff217c81aa2f3c427ffc44d1bf0))
* move dojo curriculum to uFawkesDojo repo ([596955b](https://github.com/paruff/fawkes/commit/596955bf066334b48492df5d23901cf11bd4d92a))
* point README and catalog-info at uFawkesDojo repo ([26d93c0](https://github.com/paruff/fawkes/commit/26d93c0899bd23e29223bc6058d42d1cd1ac7c99))
* point README and catalog-info at uFawkesDojo repo ([0d56c82](https://github.com/paruff/fawkes/commit/0d56c8252d507c02f7d02fadff04eb45159cbd1d))
* **release:** fix version inconsistency — align README, CHANGELOG, and add release guide ([10c33a2](https://github.com/paruff/fawkes/commit/10c33a2c495d0bd795324ad16bb6b6bc2d5eb237))
* remove 44 dead links to now-archived implementation-notes/plan ([f01502d](https://github.com/paruff/fawkes/commit/f01502d29325efb515e181d55ec819c090922e6d))
* remove fictional testimonials and non-existent community links ([1c92412](https://github.com/paruff/fawkes/commit/1c92412dd5bd6ddde1e43b9d7c1e969219baebb7))
* remove fictional testimonials and non-existent community links from README ([ed8dbd0](https://github.com/paruff/fawkes/commit/ed8dbd0c1fc564bb5b9d324f6ed45f4aecef05f3))
* **research:** add DORA research index with summaries and Fawkes implications ([f40274d](https://github.com/paruff/fawkes/commit/f40274d2f3ed680e3cae0661bed2085bd8509d98))
* **superpowers:** add securityContext hardening design for issue [#1583](https://github.com/paruff/fawkes/issues/1583) ([1843af1](https://github.com/paruff/fawkes/commit/1843af1c2cc325c178804d44ce581d5f6ebdc7d2))
* **superpowers:** add securityContext hardening design for issue [#1584](https://github.com/paruff/fawkes/issues/1584) ([4b109dc](https://github.com/paruff/fawkes/commit/4b109dcc4bde2f7fe4b3d0ac3012bae0e561c3b0))
* update plan with post-MVP roadmap (Phases 3-5) ([1b82749](https://github.com/paruff/fawkes/commit/1b827495ac2f45977b953b9d11555cc8eb5fce12))
* update PROJECT_STATUS.md to reflect June 2026 reality ([9844112](https://github.com/paruff/fawkes/commit/98441123d762aadcbb7edd2d46880826baf99ff0))


### Changed

* **ci:** extract composite action for Python environment setup ([9883ee6](https://github.com/paruff/fawkes/commit/9883ee6f9b9f7eb15ad570009b58ace8c64fdb88))


### Chores

* add .claudeignore and CLAUDE.md to workspace ([3dc07ba](https://github.com/paruff/fawkes/commit/3dc07bacdaa25f96ad47ee54dbf0395a5924340b))
* add platform skills to .agents/skills ([78b5441](https://github.com/paruff/fawkes/commit/78b54416656168782b3ddd0f4f53b0ced74f2e11))
* bump pre-commit hooks to latest, move Python to 3.13 ([790635e](https://github.com/paruff/fawkes/commit/790635e8e8279fc8e838bf906ea0639abfc054fe))
* **ci:** add OpenCode GitHub Actions workflow ([4ecf2f8](https://github.com/paruff/fawkes/commit/4ecf2f8d44ed685e6f88b6aae3cd546cf8b19794))
* **ci:** add OpenCode GitHub Actions workflow ([5125f4a](https://github.com/paruff/fawkes/commit/5125f4a6c5f48282d4a1b3ad912dca24d5ad8448))
* **ci:** bump pinned tool versions to latest stable (2026-08) ([fdb9fec](https://github.com/paruff/fawkes/commit/fdb9fec1d99b7594ee4a7b48536490394144104a))
* **ci:** bump pinned tool versions to latest stable (2026-08) ([accbca9](https://github.com/paruff/fawkes/commit/accbca95dd6a9d5516dc69c1b8f3a0d6f5780c9a))
* **ci:** pin all third-party actions to commit SHA (deterministic builds, part 2/3) ([3a213c4](https://github.com/paruff/fawkes/commit/3a213c479ae055df1639bf7096947e61207d8de8))
* **ci:** pin all third-party actions to commit SHA (deterministic builds, part 2/3) ([fa0e7fd](https://github.com/paruff/fawkes/commit/fa0e7fd7ce2c459cfaee404ca400fc8e6c686ad1))
* **ci:** pin all tool versions to latest stable (deterministic builds, part 1/3) ([f3cf0aa](https://github.com/paruff/fawkes/commit/f3cf0aaa6c8afd2f4679b81a9dc3f3224052f890))
* **ci:** pin all tool versions to latest stable for deterministic builds ([b474142](https://github.com/paruff/fawkes/commit/b474142a95399d4d0581a31d4aa9493ecdd084b7))
* **ci:** trigger PR sync after head.sha desync ([922c11b](https://github.com/paruff/fawkes/commit/922c11b864f5c96cd6547730a7dd7abf01f14ab2))
* delete ~180 files of over-engineering ([53e2d54](https://github.com/paruff/fawkes/commit/53e2d54be5f28c04337dbeff7e280df41698aa9d))
* delete ~180 files of over-engineering across the repo ([85795c0](https://github.com/paruff/fawkes/commit/85795c0e0fb3085a566091d46c366d846b309209))
* delete infra/terraform/aks and its orphaned terratest coverage ([86fe38b](https://github.com/paruff/fawkes/commit/86fe38bcacd6aed40c0c6828bfd91425f00ee69f))
* **deps-dev:** bump bandit from 1.8.3 to 1.9.4 ([5c51b04](https://github.com/paruff/fawkes/commit/5c51b04d884c77e5b305f332801fff06423cb17b))
* **deps-dev:** bump bandit from 1.8.3 to 1.9.4 ([fdf1874](https://github.com/paruff/fawkes/commit/fdf1874582f7eac1bf55f7d6b6ae8c70ba23db22))
* **deps-dev:** bump bandit from 1.8.3 to 1.9.4 ([b02984c](https://github.com/paruff/fawkes/commit/b02984c7fda24074f064d610d8fc9a3720e375a5))
* **deps-dev:** bump bandit from 1.8.3 to 1.9.4 ([ed361c0](https://github.com/paruff/fawkes/commit/ed361c0364c88adebf5f9565e256d0d86384e90e))
* **deps-dev:** bump black from 24.10.0 to 26.3.1 in /services/samples/sample-python-app ([229adf8](https://github.com/paruff/fawkes/commit/229adf894a454a7a0819ee62c374eff9d1df3de7))
* **deps-dev:** bump black from 26.3.1 to 26.5.1 ([b4ac8bc](https://github.com/paruff/fawkes/commit/b4ac8bcd265f730cf9008abe47bfea4dc47ab314))
* **deps-dev:** bump black from 26.3.1 to 26.5.1 ([b7f42a8](https://github.com/paruff/fawkes/commit/b7f42a8823f5ab908debaaaf36391e3b3ac461dc))
* **deps-dev:** bump black in /services/samples/sample-python-app ([8984d7b](https://github.com/paruff/fawkes/commit/8984d7b27933bacc6f1005d4940a1f6e6d5c5993))
* **deps-dev:** bump gitpython from 3.1.46 to 3.1.52 ([c3f2018](https://github.com/paruff/fawkes/commit/c3f20189047dab314f9a9572da85ba32265d8d07))
* **deps-dev:** bump gitpython from 3.1.46 to 3.1.52 ([bfa1b37](https://github.com/paruff/fawkes/commit/bfa1b375337dad25e4db21cca32d5ce6d4ea5372))
* **deps-dev:** bump gitpython from 3.1.54 to 3.1.58 ([d234eb1](https://github.com/paruff/fawkes/commit/d234eb1d44ca79f167b1405fd5c8ccce30d0a472))
* **deps-dev:** bump gitpython from 3.1.58 to 3.1.59 ([#1635](https://github.com/paruff/fawkes/issues/1635)) ([dbc2372](https://github.com/paruff/fawkes/commit/dbc2372fe27bc3dc538f4298874af4747d3b3779))
* **deps-dev:** bump gitpython from 3.1.59 to 3.1.60 ([#1669](https://github.com/paruff/fawkes/issues/1669)) ([ea9fc22](https://github.com/paruff/fawkes/commit/ea9fc2271a18ef3398d52a51c5f3c55b8d9b47c8))
* **deps-dev:** bump gitpython in the pip group across 1 directory ([639f929](https://github.com/paruff/fawkes/commit/639f929c220b173a8208c3997a16d50fa8449030))
* **deps-dev:** bump hypothesis from 6.151.9 to 6.157.0 ([a9d4d59](https://github.com/paruff/fawkes/commit/a9d4d59f922c3d3f340d71e3a7d66325642e0cae))
* **deps-dev:** bump hypothesis from 6.151.9 to 6.157.0 ([d40331e](https://github.com/paruff/fawkes/commit/d40331ef84cdb32e731e7510fa342aded69b9b01))
* **deps-dev:** bump hypothesis from 6.157.0 to 6.161.6 ([c176aba](https://github.com/paruff/fawkes/commit/c176abac697a10aab15ad7db78928cf786bd2d94))
* **deps-dev:** bump hypothesis from 6.161.6 to 6.164.0 ([658ec49](https://github.com/paruff/fawkes/commit/658ec495e1c1bd5682df644009e8f307284f9c75))
* **deps-dev:** bump hypothesis from 6.164.0 to 6.165.2 ([45a8d69](https://github.com/paruff/fawkes/commit/45a8d69ef1b46e0cdfb1d4d30a538bf689a475eb))
* **deps-dev:** bump hypothesis from 6.165.2 to 6.165.7 ([e61b71f](https://github.com/paruff/fawkes/commit/e61b71fe1a39802f0e3b14858990bf3ab258881a))
* **deps-dev:** bump hypothesis from 6.165.2 to 6.165.7 ([8811ab3](https://github.com/paruff/fawkes/commit/8811ab3bda370d20fc9ab883bc02562047fb7fe6))
* **deps-dev:** bump hypothesis from 6.165.7 to 6.165.10 ([#1638](https://github.com/paruff/fawkes/issues/1638)) ([6029d3e](https://github.com/paruff/fawkes/commit/6029d3e9e0d3b1b2509f6e01bd2bec1eae4571b6))
* **deps-dev:** bump ipython from 9.11.0 to 9.15.0 ([f5721fa](https://github.com/paruff/fawkes/commit/f5721fa640d89d9610dd11be095495d2a989248c))
* **deps-dev:** bump ipython from 9.15.0 to 9.16.0 ([d2c1563](https://github.com/paruff/fawkes/commit/d2c15637fcef05b412304b25c336dbaf11d39015))
* **deps-dev:** bump ipython from 9.16.0 to 9.16.1 ([0bf0c4d](https://github.com/paruff/fawkes/commit/0bf0c4d52f1d0b961c5ea8cd4a72bae2e0c75aa8))
* **deps-dev:** bump ipython from 9.16.1 to 9.17.0 ([#1671](https://github.com/paruff/fawkes/issues/1671)) ([0977751](https://github.com/paruff/fawkes/commit/097775115b895e4bd44f08cf03f471405db40748))
* **deps-dev:** bump kubernetes from 35.0.0 to 36.0.3 ([18b000e](https://github.com/paruff/fawkes/commit/18b000ed49ca02dd31b730fd0ff43eebcc2af64a))
* **deps-dev:** bump kubernetes from 35.0.0 to 36.0.3 ([0002fc5](https://github.com/paruff/fawkes/commit/0002fc57a01d59fade36dfd1da7159467db77bcd))
* **deps-dev:** bump markdown-it-py from 4.0.0 to 4.2.0 ([8b9fe8c](https://github.com/paruff/fawkes/commit/8b9fe8c61865cd79bc0376a5e86b002aec099672))
* **deps-dev:** bump mypy from 1.19.1 to 2.1.0 ([9e2385a](https://github.com/paruff/fawkes/commit/9e2385a05db181efe1b3156d5540db89ec9e774c))
* **deps-dev:** bump mypy from 1.19.1 to 2.1.0 ([4ea521a](https://github.com/paruff/fawkes/commit/4ea521ac239a6e8eb9bb3233fd45958486e42146))
* **deps-dev:** bump mypy from 2.1.0 to 2.3.0 ([fb8d6d2](https://github.com/paruff/fawkes/commit/fb8d6d2fb07dea1c46268765efb2327acdf92d6b))
* **deps-dev:** bump mypy from 2.3.0 to 2.3.1 ([#1636](https://github.com/paruff/fawkes/issues/1636)) ([88184d1](https://github.com/paruff/fawkes/commit/88184d1fbaf67a3658f1227e52df4f9724e9b9b2))
* **deps-dev:** bump pre-commit from 4.5.1 to 4.6.0 ([6dc5022](https://github.com/paruff/fawkes/commit/6dc5022bd5778e1591a291410bba9d57b5ab5031))
* **deps-dev:** bump pre-commit from 4.5.1 to 4.6.0 ([d04e171](https://github.com/paruff/fawkes/commit/d04e1712312e6a7fd8e486fbd3e1739c9ba56fa9))
* **deps-dev:** bump pre-commit from 4.6.0 to 4.6.1 ([8946467](https://github.com/paruff/fawkes/commit/89464678e78b7ce972b82622659b3ac7a6f27a08))
* **deps-dev:** bump pre-commit from 4.6.1 to 4.6.2 ([bf7e4e8](https://github.com/paruff/fawkes/commit/bf7e4e80d86ba4186c0f71314198e8d2a484a131))
* **deps-dev:** bump pre-commit from 4.6.1 to 4.6.2 ([a524bbf](https://github.com/paruff/fawkes/commit/a524bbf61aaaee5286a7dc87b18d6f478a3faa0e))
* **deps-dev:** bump pylint from 4.0.5 to 4.0.6 ([ab470d1](https://github.com/paruff/fawkes/commit/ab470d1bdbd7e872f598d2b626cc8c405d880622))
* **deps-dev:** bump pylint from 4.0.5 to 4.0.6 ([1f24df2](https://github.com/paruff/fawkes/commit/1f24df205af14e13d58d2c15a05d3ceb27b68c91))
* **deps-dev:** bump pylint from 4.0.6 to 4.0.7 ([09e3000](https://github.com/paruff/fawkes/commit/09e3000f202f2678176f8dbc0edd21466059b9b6))
* **deps-dev:** bump pylint from 4.0.6 to 4.0.7 ([2efd929](https://github.com/paruff/fawkes/commit/2efd9294c51150823a5bca6b0700edc3d004983e))
* **deps-dev:** bump pytest from 9.0.3 to 9.1.1 ([c58a300](https://github.com/paruff/fawkes/commit/c58a30082b36ca52fe4c5d174119aa67d4878dd7))
* **deps-dev:** bump pytest from 9.0.3 to 9.1.1 ([4b8b9d4](https://github.com/paruff/fawkes/commit/4b8b9d45533dafeae464c91ffff4fa7b1c265b8d))
* **deps-dev:** bump pytest-asyncio from 1.3.0 to 1.4.0 ([3c44cae](https://github.com/paruff/fawkes/commit/3c44caed68c9e858ef4496047142ac39c7c164ea))
* **deps-dev:** bump pytest-asyncio from 1.3.0 to 1.4.0 ([37fe0bf](https://github.com/paruff/fawkes/commit/37fe0bf5d55d54fc4d5f55df33f6731a124461ff))
* **deps-dev:** bump pytest-cov from 7.0.0 to 7.1.0 ([b9b2f6f](https://github.com/paruff/fawkes/commit/b9b2f6f3fad5ca3e22ac58b6daee8ac9523d2ae0))
* **deps-dev:** bump pytest-cov from 7.0.0 to 7.1.0 ([038c593](https://github.com/paruff/fawkes/commit/038c5936dc96b03d7379888c4adc070c26011b6f))
* **deps-dev:** bump requests from 2.33.0 to 2.34.2 ([290be0c](https://github.com/paruff/fawkes/commit/290be0ce99eb94a4cb41768015f5ce81f96cbab8))
* **deps-dev:** bump rich from 14.3.3 to 15.0.0 ([a956517](https://github.com/paruff/fawkes/commit/a9565176db8b62fbc17be5c8b6209200fb982180))
* **deps-dev:** bump ruff from 0.15.17 to 0.15.18 ([917fdde](https://github.com/paruff/fawkes/commit/917fdde44e0d61ff04d43cb1b37eeb360e191ec0))
* **deps-dev:** bump ruff from 0.15.17 to 0.15.18 ([0f4503e](https://github.com/paruff/fawkes/commit/0f4503ec5192b9fa20ea3e4f99b24bfc3a01c7a4))
* **deps-dev:** bump ruff from 0.15.18 to 0.15.22 ([f29e3ea](https://github.com/paruff/fawkes/commit/f29e3ead3d0fdda12a98eaf8cac9eecc024082f3))
* **deps-dev:** bump ruff from 0.15.22 to 0.16.0 ([438494b](https://github.com/paruff/fawkes/commit/438494b5bca88dd26c5cdafbfe89b298473e9dd7))
* **deps-dev:** bump ruff from 0.15.6 to 0.15.17 ([e0fdc8c](https://github.com/paruff/fawkes/commit/e0fdc8c81361957c9d5d62cf5c7ae668b748d993))
* **deps-dev:** bump ruff from 0.15.6 to 0.15.17 ([fe9ea2a](https://github.com/paruff/fawkes/commit/fe9ea2aba4b72256b553b371a4c4ed8709170337))
* **deps-dev:** bump ruff from 0.16.0 to 0.16.1 ([6528106](https://github.com/paruff/fawkes/commit/6528106b45a0e10f3bca0238881aa35fb3b85e4a))
* **deps-dev:** bump ruff from 0.16.1 to 0.16.3 ([de5b947](https://github.com/paruff/fawkes/commit/de5b947862165ce3cca5b47bee6928a193e428c5))
* **deps-dev:** bump ruff from 0.16.1 to 0.16.3 ([b9beeec](https://github.com/paruff/fawkes/commit/b9beeecb08efc9be280120bda9610fcdc0bf06bd))
* **deps-dev:** bump ruff from 0.16.3 to 0.16.4 ([#1637](https://github.com/paruff/fawkes/issues/1637)) ([7b04554](https://github.com/paruff/fawkes/commit/7b04554bfa489515b49bf283a0c9726f6829e560))
* **deps-dev:** bump ruff from 0.16.4 to 0.16.5 ([#1668](https://github.com/paruff/fawkes/issues/1668)) ([4badbf7](https://github.com/paruff/fawkes/commit/4badbf7201f8ff2fb1188b51bb05850b5fd9aa2d))
* **deps-dev:** bump ruff from 0.9.10 to 0.15.6 ([7c12a94](https://github.com/paruff/fawkes/commit/7c12a94116782c659bf79acac062efae39175a21))
* **deps-dev:** bump ruff from 0.9.10 to 0.15.6 ([ebd7890](https://github.com/paruff/fawkes/commit/ebd7890e5e542f5fbc27ec4f6c8ca0f5eabb056c))
* **deps-dev:** bump the pip group across 1 directory with 2 updates ([d7df67e](https://github.com/paruff/fawkes/commit/d7df67ecec7db3fad2b73add78e64de1ab9d0f48))
* **deps-dev:** bump the pip group across 1 directory with 2 updates ([46a1948](https://github.com/paruff/fawkes/commit/46a19480386df87788a0f5ef95cc7f9d3f65eb5a))
* **deps-dev:** bump weaviate-client from 4.20.3 to 4.20.4 ([a172861](https://github.com/paruff/fawkes/commit/a172861d6c19da72a1bd118171f6e87fd8a8ff33))
* **deps-dev:** bump weaviate-client from 4.20.3 to 4.20.4 ([c2cf904](https://github.com/paruff/fawkes/commit/c2cf9046898ae14101aea080c08c5c1763bda7db))
* **deps-dev:** bump weaviate-client from 4.20.4 to 4.22.0 ([ce96476](https://github.com/paruff/fawkes/commit/ce9647680c05d80b8ff8b0721a40b0807d2fd1cd))
* **deps-dev:** bump weaviate-client from 4.22.0 to 4.23.0 ([1848253](https://github.com/paruff/fawkes/commit/1848253a070328a50e5b37b6f8bafe4aaf5cf871))
* **deps-dev:** bump weaviate-client from 4.22.0 to 4.23.0 ([f05d0a8](https://github.com/paruff/fawkes/commit/f05d0a8da89db2252d65329308469aab0d20bd84))
* **deps:** bump actions/cache from 5 to 6 ([35797d3](https://github.com/paruff/fawkes/commit/35797d34d554ceacf0858d6882d6bbc3329aa293))
* **deps:** bump actions/cache from 5 to 6 ([1b28249](https://github.com/paruff/fawkes/commit/1b28249b45cd56aea45f6a310b379cfd9722486c))
* **deps:** bump actions/checkout from 4 to 6 ([7a61667](https://github.com/paruff/fawkes/commit/7a616676da2da08a7d043e1f3330d1badb404874))
* **deps:** bump actions/checkout from 4 to 6 ([3003738](https://github.com/paruff/fawkes/commit/30037380e5780fd2d7e77a4515b1bbe5cd8ac2e6))
* **deps:** bump actions/checkout from 6 to 7 ([4f30c84](https://github.com/paruff/fawkes/commit/4f30c84dfc278ac1acaa6e2553a074f5b845e6db))
* **deps:** bump actions/checkout from 6 to 7 ([4c8e34d](https://github.com/paruff/fawkes/commit/4c8e34db4c34d3c9d00177d46709c003b86fbe3e))
* **deps:** bump actions/dependency-review-action from 4 to 5 ([e9d5207](https://github.com/paruff/fawkes/commit/e9d5207a845f2229ab1d3ff9b63d39f903abc986))
* **deps:** bump actions/dependency-review-action from 4 to 5 ([864f486](https://github.com/paruff/fawkes/commit/864f4864200174cdcfa3e6e85f33830f43d11cbf))
* **deps:** bump actions/github-script from 7 to 8 ([f2e502b](https://github.com/paruff/fawkes/commit/f2e502ba970ab913bc0bd80f03136a20ea111e1c))
* **deps:** bump actions/github-script from 7 to 8 ([d462af1](https://github.com/paruff/fawkes/commit/d462af1dc4b23c052c47f8071d5584f6300d8b60))
* **deps:** bump actions/github-script from 8 to 9 ([bbcc094](https://github.com/paruff/fawkes/commit/bbcc0940727a0699b254b715d551f565f4d3d4b9))
* **deps:** bump actions/github-script from 8 to 9 ([9f242d9](https://github.com/paruff/fawkes/commit/9f242d9e9dcc8eba225ced57fd95ae1a0248697b))
* **deps:** bump actions/github-script from 8 to 9 ([8dd47e1](https://github.com/paruff/fawkes/commit/8dd47e1eafe4be6576db3ad7e1171e82bf17b971))
* **deps:** bump actions/github-script from 8 to 9 ([5144733](https://github.com/paruff/fawkes/commit/51447339cd386557c63e5bed517685ee4a331b8b))
* **deps:** bump actions/setup-go from 5 to 6 ([093fcd4](https://github.com/paruff/fawkes/commit/093fcd4f277ca5bd36df849d8865b68e1b9100a7))
* **deps:** bump actions/setup-go from 5 to 6 ([f075955](https://github.com/paruff/fawkes/commit/f0759556c49fbb5eb8e1c702779f39921948e07a))
* **deps:** bump actions/setup-go from 6 to 7 ([7bfbdda](https://github.com/paruff/fawkes/commit/7bfbddaafb0a804a2c2709908265606cd3a0cdfa))
* **deps:** bump actions/setup-node from 6 to 7 ([f1eaa67](https://github.com/paruff/fawkes/commit/f1eaa67e7010a04921d5d3ffaec82f2d28a8219a))
* **deps:** bump actions/setup-python from 6 to 7 ([96aeb0c](https://github.com/paruff/fawkes/commit/96aeb0c47bd407266b1788f901fa5c0c785790a0))
* **deps:** bump anchore/sbom-action from 0.23.0 to 0.23.1 in the github-actions-patch group ([f7a27fd](https://github.com/paruff/fawkes/commit/f7a27fde44cb745ccd24dde35f1cd0f69e7aeef9))
* **deps:** bump anchore/sbom-action from 0.23.1 to 0.24.0 ([d495385](https://github.com/paruff/fawkes/commit/d495385a8be77a0fbc1239c1e00b41dde478bcf5))
* **deps:** bump anchore/sbom-action from 0.23.1 to 0.24.0 ([9175c1d](https://github.com/paruff/fawkes/commit/9175c1d854073949fbdd57b70f37454ece18cdb1))
* **deps:** bump anchore/sbom-action in the github-actions-patch group ([6b3d3dd](https://github.com/paruff/fawkes/commit/6b3d3ddb3ccd0def102d85fd6c43b8edd50eb3eb))
* **deps:** bump anomalyco/opencode/github ([#1639](https://github.com/paruff/fawkes/issues/1639)) ([5a297ca](https://github.com/paruff/fawkes/commit/5a297ca60a1b4dc3e5cbbceb558336c0c4119be5))
* **deps:** bump aquasecurity/setup-trivy from 0.2.6 to 0.3.1 ([ab1702c](https://github.com/paruff/fawkes/commit/ab1702c4c1417cfc8ea59fbfac57cdf0e43fc677))
* **deps:** bump aquasecurity/setup-trivy from 0.2.6 to 0.3.1 ([6bbf970](https://github.com/paruff/fawkes/commit/6bbf97021893704f0fdfe7147b4490056e502665))
* **deps:** bump aquasecurity/trivy-action from 0.28.0 to 0.36.0 ([d98a1d8](https://github.com/paruff/fawkes/commit/d98a1d853a95459aaeb100edd234fc6657377d64))
* **deps:** bump aquasecurity/trivy-action from 0.28.0 to 0.36.0 ([0e50411](https://github.com/paruff/fawkes/commit/0e504114b19769aa894281aa2b17b5df5d66e17c))
* **deps:** bump azure/login from 2 to 3 ([7b27241](https://github.com/paruff/fawkes/commit/7b272417459c9d1670eb7a381677fbaf9912eff3))
* **deps:** bump azure/login from 2 to 3 ([399aa0a](https://github.com/paruff/fawkes/commit/399aa0a214bf9692563af675397b0e7d4dd00876))
* **deps:** bump azure/setup-helm from 4 to 5 ([5575448](https://github.com/paruff/fawkes/commit/55754485e53ce0fb93632d81a41bb27df27c41df))
* **deps:** bump azure/setup-helm from 4 to 5 ([17d13c2](https://github.com/paruff/fawkes/commit/17d13c25359d6d870e1cedb21b011ea3e829f637))
* **deps:** bump azure/setup-kubectl from 4 to 5 ([920af25](https://github.com/paruff/fawkes/commit/920af257e8a6340c89d5a5b95e679c2e61f26eb7))
* **deps:** bump azure/setup-kubectl from 4 to 5 ([68e70a4](https://github.com/paruff/fawkes/commit/68e70a4d0d47302af86a5bca6d32857fed11ef40))
* **deps:** bump docker/build-push-action from 6 to 7 ([484b3f8](https://github.com/paruff/fawkes/commit/484b3f8b356fb482dbe4008b5f0158b44e3fb4a2))
* **deps:** bump docker/build-push-action from 6 to 7 ([9000c36](https://github.com/paruff/fawkes/commit/9000c36eb7d7f83c16697b5ca15f3c4e0f11f543))
* **deps:** bump docker/login-action from 3 to 4 ([b616b5e](https://github.com/paruff/fawkes/commit/b616b5ec1bbc1ad7495ccbbf8a649a82c87577a9))
* **deps:** bump docker/login-action from 3 to 4 ([49e6eb7](https://github.com/paruff/fawkes/commit/49e6eb7a2c0d20caede98b4019bdebd10690a94d))
* **deps:** bump docker/metadata-action from 5 to 6 ([553f43b](https://github.com/paruff/fawkes/commit/553f43ba72309e4dface12bca85e6b532600b82c))
* **deps:** bump docker/metadata-action from 5 to 6 ([d2bb57f](https://github.com/paruff/fawkes/commit/d2bb57f014e436794dd9c90340c05b78c2a7d4a9))
* **deps:** bump docker/setup-buildx-action from 3 to 4 ([7bc3e31](https://github.com/paruff/fawkes/commit/7bc3e3161ab67bce87185bb4c2185f4ef47fb3c0))
* **deps:** bump docker/setup-buildx-action from 3 to 4 ([5b14771](https://github.com/paruff/fawkes/commit/5b147715dbea9aa0cf111bf102edeae65e1d410b))
* **deps:** bump docker/setup-buildx-action from 4.2.0 to 4.3.0 ([#1640](https://github.com/paruff/fawkes/issues/1640)) ([03fe42c](https://github.com/paruff/fawkes/commit/03fe42c06e5609947ed6c7202cf6e9ddb80f50ca))
* **deps:** bump google.golang.org/grpc ([#1673](https://github.com/paruff/fawkes/issues/1673)) ([34ed8a5](https://github.com/paruff/fawkes/commit/34ed8a549b8db6806727f02f85e4e4b0dbf0697c))
* **deps:** bump hashicorp/aws from 6.35.1 to 6.36.0 in /infra/aws ([6c915c6](https://github.com/paruff/fawkes/commit/6c915c6dccbcd626f62862888df5e26edc29c6e8))
* **deps:** bump hashicorp/aws from 6.35.1 to 6.36.0 in /infra/aws ([930f7e4](https://github.com/paruff/fawkes/commit/930f7e420f42f1bdf60ff5086444dbc4a32c2f5d))
* **deps:** bump hashicorp/aws from 6.49.0 to 6.50.0 in /infra/aws ([a95bd67](https://github.com/paruff/fawkes/commit/a95bd671fcca50fcc71b285a1f7957e1cbd8468d))
* **deps:** bump hashicorp/aws from 6.49.0 to 6.50.0 in /infra/aws ([83cd185](https://github.com/paruff/fawkes/commit/83cd18538b5e6d702b83a2c60d6fb395f1ca9f8d))
* **deps:** bump hashicorp/aws from 6.50.0 to 6.51.0 in /infra/aws ([227fa28](https://github.com/paruff/fawkes/commit/227fa28e5a6475ae1812f1f747a8624f53f6f115))
* **deps:** bump hashicorp/aws from 6.50.0 to 6.51.0 in /infra/aws ([af554eb](https://github.com/paruff/fawkes/commit/af554eb273f37e817e7186113075c7d624504f69))
* **deps:** bump hashicorp/aws from 6.57.1 to 6.58.0 in /infra/aws ([03f8f18](https://github.com/paruff/fawkes/commit/03f8f188431ff20386a40e86e6dd57fb51230b68))
* **deps:** bump hashicorp/azurerm from 4.63.0 to 4.64.0 in /infra/azure ([17c89cb](https://github.com/paruff/fawkes/commit/17c89cb2a37f6a570d098fff728b66549daf4c21))
* **deps:** bump hashicorp/azurerm from 4.64.0 to 4.77.0 in /infra/azure ([32ff99c](https://github.com/paruff/fawkes/commit/32ff99c5b0eb0c0ab6023117e04340541f91d29d))
* **deps:** bump hashicorp/azurerm from 4.77.0 to 4.78.0 in /infra/azure ([011a56f](https://github.com/paruff/fawkes/commit/011a56f50908614eac8aa889040ae8efd0ed8601))
* **deps:** bump hashicorp/azurerm from 4.78.0 to 4.81.0 in /infra/azure ([f3db4ce](https://github.com/paruff/fawkes/commit/f3db4cef6609781ac79788abb97c975d19c2f442))
* **deps:** bump hashicorp/azurerm from 4.81.0 to 5.0.1 in /infra/azure ([c0773a9](https://github.com/paruff/fawkes/commit/c0773a95aa344193c33a1a8022194f066163b0b1))
* **deps:** bump hashicorp/azurerm from 5.0.1 to 5.1.0 in /infra/azure ([5a8c0d3](https://github.com/paruff/fawkes/commit/5a8c0d35cb707ebe220895240a32fb03933b41a9))
* **deps:** bump hashicorp/azurerm from 5.0.1 to 5.1.0 in /infra/azure ([9b4b8be](https://github.com/paruff/fawkes/commit/9b4b8be8d8d1917ef4a015631f08f48d9d60b865))
* **deps:** bump hashicorp/azurerm from 5.1.0 to 5.2.0 in /infra/azure ([#1634](https://github.com/paruff/fawkes/issues/1634)) ([e7fade9](https://github.com/paruff/fawkes/commit/e7fade990d37b002b4718017e1426775fde42f87))
* **deps:** bump hashicorp/azurerm from 5.2.0 to 5.3.0 in /infra/azure ([#1667](https://github.com/paruff/fawkes/issues/1667)) ([467d70e](https://github.com/paruff/fawkes/commit/467d70e8c7f585929762c7138d94544fe39a568e))
* **deps:** bump hashicorp/azurerm in /infra/azure ([1df301c](https://github.com/paruff/fawkes/commit/1df301c4dbca1a3a98055c14f4926ac59a0f7cc5))
* **deps:** bump hashicorp/azurerm in /infra/azure ([c4bd897](https://github.com/paruff/fawkes/commit/c4bd8972448ada529f785c3de29d11ce7e1b8347))
* **deps:** bump hashicorp/azurerm in /infra/azure ([4de86ee](https://github.com/paruff/fawkes/commit/4de86ee849d44531cb2184458a002ea7239fb978))
* **deps:** bump hashicorp/azurerm in /infra/azure ([801bcc9](https://github.com/paruff/fawkes/commit/801bcc9282873e4ed35218cc9df130aa904fb597))
* **deps:** bump hashicorp/http from 3.5.0 to 3.6.0 in /infra/azure ([f731213](https://github.com/paruff/fawkes/commit/f731213de269949af33e8bfc8d7ee3bd5517148a))
* **deps:** bump hashicorp/http from 3.5.0 to 3.6.0 in /infra/azure ([c7c5895](https://github.com/paruff/fawkes/commit/c7c58951f3d55764a80ddba36f059db30239274e))
* **deps:** bump hashicorp/http from 3.6.0 to 3.6.1 in /infra/azure ([#1633](https://github.com/paruff/fawkes/issues/1633)) ([d660405](https://github.com/paruff/fawkes/commit/d660405bfbb15a4ce2d40fc147b52e0a36cc74ca))
* **deps:** bump hashicorp/kubernetes from 3.2.0 to 3.2.1 in /infra/aws ([c5d2504](https://github.com/paruff/fawkes/commit/c5d2504f6795c7548c65a4a6f985e0fb3fd62fec))
* **deps:** bump hashicorp/kubernetes from 3.2.0 to 3.2.1 in /infra/aws ([14b90ce](https://github.com/paruff/fawkes/commit/14b90ce272a6cdf0f52916a7ebbfa0c0f8be0537))
* **deps:** bump hashicorp/time from 0.13.1 to 0.14.0 in /infra/azure ([eb617f1](https://github.com/paruff/fawkes/commit/eb617f10a03469a8636d49ed77fd5e739c703922))
* **deps:** bump hashicorp/time from 0.13.1 to 0.14.0 in /infra/azure ([3df31a6](https://github.com/paruff/fawkes/commit/3df31a69cd770113c5f81f520d1c0ceab109847e))
* **deps:** bump hashicorp/time from 0.14.0 to 0.14.1 in /infra/azure ([#1632](https://github.com/paruff/fawkes/issues/1632)) ([611f09c](https://github.com/paruff/fawkes/commit/611f09c823f6f27d9a4f1f04ec45f8df040473fa))
* **deps:** bump infracost/actions from 3 to 4 ([26be72d](https://github.com/paruff/fawkes/commit/26be72d22330f816baec1bc9a07203334a0da98d))
* **deps:** bump infracost/actions from 3 to 4 ([a13bb4d](https://github.com/paruff/fawkes/commit/a13bb4d9595a2b67ada9ae4d03ab11995eb127f5))
* **deps:** bump py-cov-action/python-coverage-comment-action ([7ba7b31](https://github.com/paruff/fawkes/commit/7ba7b31cb03e362cbc2a71dfa0e0d16954a6d33a))
* **deps:** bump py-cov-action/python-coverage-comment-action from 4.1 to 4.3 ([8d7edf4](https://github.com/paruff/fawkes/commit/8d7edf479a71f01f08379855217dc5939d1e33fe))
* **deps:** bump pymdown-extensions from 11.0.1 to 11.0.2 ([#1670](https://github.com/paruff/fawkes/issues/1670)) ([ec97e58](https://github.com/paruff/fawkes/commit/ec97e58235d8f335c329d661023144fe0c71a6f4))
* **deps:** bump python from 3.13.14-slim to 3.14.7-slim in /services/mcp-k8s-server ([61f2d43](https://github.com/paruff/fawkes/commit/61f2d434a386036cc24976fbe943854b99b6945b))
* **deps:** bump python in /services/mcp-k8s-server ([d64d6ab](https://github.com/paruff/fawkes/commit/d64d6ab9018fc6de092a7bebd3cf156a09bcb002))
* **deps:** bump python in /services/mcp-k8s-server ([3291a77](https://github.com/paruff/fawkes/commit/3291a774e16b7fa74cae94c759c8cb1973600bb5))
* **deps:** bump python-multipart ([ece6797](https://github.com/paruff/fawkes/commit/ece6797c8bf79822170f4be4758b0afac21400f1))
* **deps:** bump python-multipart from 0.0.27 to 0.0.31 in /services/feedback-bot in the pip group across 1 directory ([6f2eda9](https://github.com/paruff/fawkes/commit/6f2eda9b7aa6d6771060f5a311af502b624decee))
* **deps:** bump requests ([35c7dad](https://github.com/paruff/fawkes/commit/35c7dadbdff7c3954934d5af5341d8030d61d31e))
* **deps:** bump requests from 2.31.0 to 2.32.4 in /extensions/ai/services/rag ([3b707b6](https://github.com/paruff/fawkes/commit/3b707b69e9c663c509378a6b022b4536501b9a73))
* **deps:** bump requests from 2.31.0 to 2.32.4 in /extensions/data-platform/services/data-quality ([855dafb](https://github.com/paruff/fawkes/commit/855dafb95e42d4a5160e8035758a6a65233ec4b7))
* **deps:** bump requests in /extensions/ai/services/rag ([0525c04](https://github.com/paruff/fawkes/commit/0525c0457b4616e5061a55f99ce4f6b119b7b704))
* **deps:** bump sigstore/cosign-installer ([2ddba04](https://github.com/paruff/fawkes/commit/2ddba049b26259f0258d53a4e0ca703af23019a1))
* **deps:** bump sigstore/cosign-installer from 4.0.0 to 4.1.0 ([35a35a4](https://github.com/paruff/fawkes/commit/35a35a487eed433c9501a6c5b8a1c4f6472751f0))
* **deps:** bump sigstore/cosign-installer from 4.0.0 to 4.1.0 ([5e97681](https://github.com/paruff/fawkes/commit/5e97681b1c938bae3bd123c553958fe44144a822))
* **deps:** bump sigstore/cosign-installer from 4.1.0 to 4.1.2 in the github-actions-patch group ([3ba6ed5](https://github.com/paruff/fawkes/commit/3ba6ed57ebd5265a8dbf927ed8af5d169c22153b))
* **deps:** bump the github-actions-patch group with 3 updates ([#1672](https://github.com/paruff/fawkes/issues/1672)) ([e912e65](https://github.com/paruff/fawkes/commit/e912e65ce5abf51841c41265e2ec9a15646d4a8f))
* **deps:** bump the go_modules group across 1 directory with 2 updates ([b40d8cc](https://github.com/paruff/fawkes/commit/b40d8ccd05f5b13ba02e80f7780b39d99dd351f9))
* **deps:** bump the go_modules group across 1 directory with 3 updates ([979358c](https://github.com/paruff/fawkes/commit/979358cc16d65c5aaeddbf7b7b083681f6cf85f1))
* **deps:** bump the go_modules group across 1 directory with 3 updates ([9f7783e](https://github.com/paruff/fawkes/commit/9f7783ebb8b2d75a891a51b94660bc6cf79bca74))
* **deps:** bump the pip group across 19 directories with 6 updates ([3f2f2d0](https://github.com/paruff/fawkes/commit/3f2f2d0d2ebe2e046921a7f46e184b0a1d233f57))
* **deps:** bump the pip group across 19 directories with 6 updates ([01e78eb](https://github.com/paruff/fawkes/commit/01e78eb76827e2ba25d88d27818ebf1a3a03286c))
* **deps:** update mkdocs requirement from &gt;=1.5.3 to &gt;=1.6.1 ([f13fcbb](https://github.com/paruff/fawkes/commit/f13fcbbe1609b222e7fa83a1444aae791b6640e8))
* **deps:** update mkdocs requirement from &gt;=1.5.3 to &gt;=1.6.1 ([29657e8](https://github.com/paruff/fawkes/commit/29657e8238ec8ee8f3e8f7525fc0a2b709533359))
* **deps:** update mkdocs-material requirement from &gt;=9.4.0 to &gt;=9.7.6 ([5c4ce7f](https://github.com/paruff/fawkes/commit/5c4ce7fde6cde51be95ac6f94f526c9641609e61))
* **deps:** update mkdocs-material requirement from &gt;=9.4.0 to &gt;=9.7.6 ([f539264](https://github.com/paruff/fawkes/commit/f539264b2dfa560ecdbfa34c5fa9122ce2b8fe81))
* **deps:** update pymdown-extensions requirement ([919c86d](https://github.com/paruff/fawkes/commit/919c86df7d467204f193876a1a96e41b138c65f0))
* **deps:** update pymdown-extensions requirement ([6c32933](https://github.com/paruff/fawkes/commit/6c329337705e732d589f3d193f0219b6a680c510))
* **deps:** update pymdown-extensions requirement from &gt;=10.0 to &gt;=10.21.3 ([193866b](https://github.com/paruff/fawkes/commit/193866b1921692654b2a2c5996aa9b0709facffd))
* **deps:** update pymdown-extensions requirement from &gt;=10.21.3 to &gt;=11.0.1 ([718487b](https://github.com/paruff/fawkes/commit/718487b563cf8c58e9edaaac3bf43d710e82fcba))
* **docker:** pin all base images to exact published tags (deterministic builds, part 3/3) ([c59f39e](https://github.com/paruff/fawkes/commit/c59f39e4cee13e1dd3a7d3dbe7d416269e6dabae))
* **docker:** pin all base images to exact published tags (deterministic builds, part 3/3) ([dd166d7](https://github.com/paruff/fawkes/commit/dd166d7709c52848e441dbf1d292a72cbb2b88d0))
* **gitops:** add reusable GitOps templates for product suite ([d0bf37b](https://github.com/paruff/fawkes/commit/d0bf37bd71f40af00a35250495c2bd2ba7c0c13e))
* **workflows:** migrate reusable workflows from uFawkesObs ([c825b3d](https://github.com/paruff/fawkes/commit/c825b3ddbbbb22c853229e79d628e23692e4cdb7))
* **workflows:** migrate reusable workflows from uFawkesObs ([234be0a](https://github.com/paruff/fawkes/commit/234be0aa97cb452c25118d1b5140b271e332c1fb))

## [Unreleased]

### Added

- Focalboard project management integration
- Mattermost collaboration platform integration
- White Belt dojo curriculum (initial modules)
- Chaos engineering integration (planned)

### Changed

- Ongoing documentation improvements and reorganization

## [0.3.0] - 2025-12-25

**Product discovery, design and adoption support**
[GitHub Release](https://github.com/paruff/fawkes/releases/tag/v0.3.0)

### Added

- User research repository structure with Git LFS and file validation
- Research-validated user personas with Backstage catalog integration
- Structured interview guides for platform user research
- Insights Database and Tracking System — REST API with tagging and full-text search
- Research Insights Dashboard with Prometheus metrics exporter
- AT-E3-001 acceptance test validation script for research infrastructure
- Anomaly detection service for platform observability
- AI code review service with multi-provider LLM support
- MCP Kubernetes server for AI-assisted cluster management
- Ansible-based VM provisioning and bootstrapping
- Design system foundations (CSS/JS component library)
- Sample applications and golden-path templates

### Changed

- Documentation restructured into Diataxis-aligned knowledge base
- README navigation and getting-started flow improved
- Root-level markdown files reorganized

## [0.2.0] - 2025-12-23

**AI features and data platform**
[GitHub Release](https://github.com/paruff/fawkes/releases/tag/v0.2.0)

### Added

- Weaviate vector database deployment for RAG (Retrieval-Augmented Generation)
- RAG service for AI context retrieval with Weaviate integration
- RAG indexers for GitHub repositories and Backstage TechDocs
- AI coding assistant configured with telemetry and RAG integration
- AI usage policy documentation and governance framework
- DataHub data catalog with PostgreSQL and OpenSearch backends
- DataHub metadata ingestion for PostgreSQL, Kubernetes, Git, and CI/CD sources
- AT-E2-001 and AT-E2-002 acceptance test runners with report generation
- Security plane — SBOM generation, image signing, and OPA policy enforcement
- DORA metrics automation with Prometheus dashboards

### Changed

- CI/CD pipelines updated to enforce code quality gates (ruff, mypy, shellcheck)
- Observability stack extended with OpenTelemetry tracing

## [0.1.0] - 2025-12-21

**Initial platform foundation**
[GitHub Release](https://github.com/paruff/fawkes/releases/tag/v0.1.0)

### Added

- Core platform architecture and governance documentation
- Jenkins CI/CD with Kubernetes pod/agent support (Configuration as Code)
- Pre-commit hooks for GitOps, Terraform, Kubernetes, and IDP validation
- Infrastructure as Code with Terraform (AWS, Azure modules)
- Kubernetes orchestration manifests and Helm chart foundations
- ArgoCD GitOps application definitions
- Backstage developer portal initial deployment
- Dojo learning system design and belt-progression framework
- Multi-cloud support groundwork (AWS, Azure, GCP)
- Observability stack (Prometheus, Grafana, OpenTelemetry) — initial setup
- CHANGELOG, CONTRIBUTING, and CODE_OF_CONDUCT documentation

[Unreleased]: https://github.com/paruff/fawkes/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/paruff/fawkes/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/paruff/fawkes/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/paruff/fawkes/releases/tag/v0.1.0
