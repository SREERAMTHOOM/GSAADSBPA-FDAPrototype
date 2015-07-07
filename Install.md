##Installation instructions using Docker Container#

### Prerequisites
1. Docker software
1. InBound HTTP Port:80 should be allowed on the server that is hosting Docker Container

### Running the application on a Linux server which hosts the Docker Container/image:


1. Pull/Run the Docker image: 

	```docker run –p 80:3000 –i –t aceinfo/gsaads-prototype``` 
2. Navigate to the application directory 

	```cd /var/www/html/gsaads/```
3. Starting the application:

	```rails s –b 0.0.0.0```
 
4.  Open the application on a browser using the following URL:

	```http://IP of the Server hosting Docker image/```


##Manual Installation

###Prerequisites

1. Ruby 2.0.0p643 and above
2. Rails 4.2.2 and above
3. Phusion Passenger version 5.0.10 and above


Application Installation Instructions:<br>

1. Retrieve/clone the source code from github [Source](https://github.com/AceInfoSolutions/GSAADSBPA-FDAPrototype/tree/master/source/gsaads "Source") into the INSTALL_DIR for e.g 
`/app/gsaads` 

	```git clone https://github.com/AceInfoSolutions/GSAADSBPA-FDAPrototype/tree/master/source/gsaads```

2. Change the working directory to INSTALL_DIR

	```cd /app/gsaads```

3. Install the gems required by the application

	```bundle install```

4. Starting the application

	```rails s –b 0.0.0.0```

5. Open the application on a browser using the following URL:

	```http://IP of the Server hosting Docker image/```
