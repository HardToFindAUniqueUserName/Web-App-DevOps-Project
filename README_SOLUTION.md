# Web-App-DevOps-Project

Welcome to the Web App DevOps Project repo! This application allows you to efficiently manage and track orders for a potential business. It provides an intuitive user interface for viewing existing orders and adding new ones.

## Table of Contents

- [Version Control].(#version-control)
- [Getting Started](#getting-started)
- [Technology Stack](#technology-stack)
- [Contributors](#contributors)
- [License](#license)

# Table of contents
1. [Introduction](#introduction)
2. [Some paragraph](#paragraph1)
    1. [Sub paragraph](#subparagraph1)
3. [Another paragraph](#paragraph2)

## This is the introduction <a name="introduction"></a>
Some introduction text, formatted in heading 2 style

## Some paragraph <a name="paragraph1"></a>
The first paragraph text

### Sub paragraph <a name="subparagraph1"></a>
This is a sub paragraph, formatted in heading 3 style

## Another paragraph <a name="paragraph2"></a>
The second paragraph text


## Features

- **Order List:** View a comprehensive list of orders including details like date UUID, user ID, card number, store code, product code, product quantity, order date, and shipping date.
  
![Screenshot 2023-08-31 at 15 48 48](https://github.com/maya-a-iuga/Web-App-DevOps-Project/assets/104773240/3a3bae88-9224-4755-bf62-567beb7bf692)

- **Pagination:** Easily navigate through multiple pages of orders using the built-in pagination feature.
  
![Screenshot 2023-08-31 at 15 49 08](https://github.com/maya-a-iuga/Web-App-DevOps-Project/assets/104773240/d92a045d-b568-4695-b2b9-986874b4ed5a)

- **Add New Order:** Fill out a user-friendly form to add new orders to the system with necessary information.
  
![Screenshot 2023-08-31 at 15 49 26](https://github.com/maya-a-iuga/Web-App-DevOps-Project/assets/104773240/83236d79-6212-4fc3-afa3-3cee88354b1a)

- **Data Validation:** Ensure data accuracy and completeness with required fields, date restrictions, and card number validation.

# web-app-devops-project
The web-app-devops-project is an application provided by AICore as a component of the end-to-end pipeline project.
The application (a database management interface) is only relevant for the purpose of the project.
Key project stages are: version control, containerisation, 
Each stage will be described in more detail 
___
## Version Control
The application files can be found on a GitHub repository (https://github.com/maya-a-iuga/Web-App-DevOps-Project).
The repository was forked, and then cloned to a local repository. The repository was branched to add features and pushed back to the remote repository and merged to main. Main was subsequently pulled, and branched again. The new branch was rolled back, pushed to the remote repository and remerged into main.

### Key Commands: 
 - git clone <URI-of-repository>
 - git checkout -b <name-of-new-branch>
 - git branch
 - git add . or git add <name-of-file(s)-to-be-added>
 - git commit -m "text of meaning full comment"
  - git push -u origin <name-of-branch>
 - git pull
___
## Containerisation
A docker file was added to the repository, to define the image build and the container run.

### Dockerfile:

FROM python:3.8-slim

// # Step 2 - Set the working directory in the container
WORKDIR /app

// # Step 3 Copy the application files in the container
COPY . .

// # Install system dependencies and ODBC driver
RUN apt-get update && apt-get install -y \
    unixodbc unixodbc-dev odbcinst odbcinst1debian2 libpq-dev gcc && \
    apt-get install -y gnupg && \
    apt-get install -y wget && \
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | apt-key add - && \
    wget -qO- https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list && \
    apt-get update && \
    ACCEPT_EULA=Y apt-get install -y msodbcsql18 && \
    apt-get purge -y --auto-remove wget && \  
    apt-get clean

// # Install pip and setuptools
RUN pip install --upgrade pip setuptools

// # Step 4 - Install Python packages specified in requirements.txt
// # RUN pip install -r requirements.txt
RUN pip install --trusted-host pypi.python.org -r requirements.txt

// # Step 5 - Expose port 
EXPOSE 5000

// # Step 6 - Define Startup Command
// # ENTRYPOINT ["python", "app.py"]
CMD ["python", "app.py"]
// # CMD ["flask", "run"]


### Build:

docker build -t <image-name> .

docker images

### Run:

docker run -d -p 30030:5000 <image-name>

docker ps
docker ps -a
docker rm <container-id>

docker images -a

docker rmi <image-id>


## Contributors 

- [Maya Iuga]([https://github.com/yourusername](https://github.com/maya-a-iuga))

## License

This project is licensed under the MIT License. For more details, refer to the [LICENSE](LICENSE) file.
