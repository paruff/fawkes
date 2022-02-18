##pre-requisite 
   1. setup aws client infr/workspace/setup.bat   

# Day of, check list:
	1. Provided account access uid & pw
	2. Login to console
	3. Get access keys
	4. Aws configure
	1.1  Run AWS Security Scan using Scout2 and verify access
	4. Create ssh keys
	5. Download ssh keys
	6. cp key into .ssh/
	7. Git clone fawkes
	8. cd fawkes/infra
	9. Infra-boot.sh -k platform-use1 -w m4.xlarge -m t2.medium -e challenge
	10. … 10 minutes later
	10. 
	11. Collect and publish ???
	12. deploy the CI/CD pipeline
	12. configure Jenkins
	12. configure SonarQube
	13. run ref arch/tracer bullet in platform and envs with AAT

## Output from from systems to Delivery team
1. Platform URL to include Jenkins, SonarQube, Nexus
2. AT env URL to load balancer
3. Demo env URL to load balancer
2. URL to ELK load balancer, Centralized log platform
