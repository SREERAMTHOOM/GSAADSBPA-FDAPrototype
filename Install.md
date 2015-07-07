##Installation instructions using Docker Container#

### Prerequisites
1. Docker 1.6.0 software
1. InBound HTTP Port:80 should be allowed on the server that is hosting Docker Container

### Running the application on a Linux server which hosts the Docker Container/image:


1. Pull/Run the Docker image: 

	```docker run –p 80:3000 –i –t aceinfo/gsaadsbpa-fdaprototype``` 
2. Navigate to the application directory 

	```cd /var/www/html/gsaads/```
3. Starting the application:

	```rails s –b 0.0.0.0```
 
4.  Open the application in a browser using the following URL:

	```http://IP of the Server hosting Docker image/```


##Manual Installation

###Prerequisites

1. Ruby 2.0.0p643 and above
2. Rails 4.2.2 and above
3. ```<INSTALL_DIR>``` is the directory where application will be installed


Application Installation Instructions:<br>

1. Retrieve/clone the source code from github [Source](https://github.com/AceInfoSolutions/GSAADSBPA-FDAPrototype/tree/master/source/gsaads "Source") into a ```<TEMP_DIR>``` for e.g `/home/<user>/temp` 

	```git clone https://github.com/AceInfoSolutions/GSAADSBPA-FDAPrototype```

2. Create a working directory

	```mkdir <INSTALL_DIR>/gsaads```

	```cd <INSTALL_DIR>/gsaads```

	```cp -R /home/<user>/temp/GSAADSBPA-FDAPrototype/source/gsaads/* INSTALL_DIR/gsaads/```

3. Install gems required by the application

	```bundle install```

4. Starting the application

	```rails s –b 0.0.0.0```

5. Open the application in a browser using the following URL:

	```http://IP of the Server hosting Docker image:3000/```
