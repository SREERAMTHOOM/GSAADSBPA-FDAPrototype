Installation instructions using Docker
Prerequisites: 
1.	Docker
2.	Internet connectivity to the Docker instance

Running the application on DOCKER_HOST (Where DOCKER_HOST is any Linux based OS):
1.	Retrieve/Run the Docker image 
docker run –p 80:3000 –i –t aceinfo/gsaads-prototype 
2.	Navigate to the application directory
cd /var/www/html/gsaads/
3.	Starting the application
rails s –b 0.0.0.0	
4.	Open the application on a browser using the following URL:
http://DOCKER_HOST/
