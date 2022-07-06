# Devops Pipeline Project
This is a full CI/CD pipeline project which consists of Dockerfile, Jenkins and AWS

### Step 1:

- Fork the repo: https://github.com/a-abukar/devops-pipeline-project to your personal Github
- Clone the repo locally using: git clone http://...

### Step 2: 

- Launch TWO Ubuntu 20.04 virtual machines on AWS of t2.micro
- Tag them as: main and test-server
- Store the key-pair locally
- SSH into the main instance after chmod-ing the key-pair

### Step 3:

- Download Jenkins on the Server
- To install Jenkins you must install Java
```bash
sudo apt-get install openjdk-8-jdk
```
- Follow [this tutorial](https://www.digitalocean.com/community/tutorials/how-to-install-jenkins-on-ubuntu-20-04)
- Add the repository key
```
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
```
- Then append the Debian package repository address to the server’s `sources.list`:
```
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
```
- Install Jenkins
```
sudo apt update

sudo apt install jenkins
```
- Start Jenkins service
```
sudo systemctl start jenkins
```

### Step 4:

- Setup firewall using UFW
```
sudo ufw allow 8080

sudo ufw allow OpenSSH
sudo ufw enable

sudo ufw status
------------------------
Output
Status: active

To                         Action      From
--                         ------      ----
OpenSSH                    ALLOW       Anywhere
8080                       ALLOW       Anywhere
OpenSSH (v6)               ALLOW       Anywhere (v6)
8080 (v6)                  ALLOW       Anywhere (v6)
```

### Step 5:
- Follow the rest of [this tutorial](https://www.digitalocean.com/community/tutorials/how-to-install-jenkins-on-ubuntu-20-04)

### Step 6:

- Configure Jenkins
- Change password by clicking on your name, then configure and change password
- Create a node - go to Dashboard > manage nodes > create a node
- On the create node - choose the pathway as /home/ubuntu/jenkins
    - (this is a directory you will have to create on your VM)
- Check ‘Use WebSocket’
- Configure the node by clicking on it and downloading the necessary dependancies
- To activate the newly created node which you will have called ‘test-server’, follow the steps below:
- Copy these dependencies over to your VM using scp CLI tool (onto both the main and test-server VM)

```bash
> scp -i "<name>.pem" agent.jar jenkins-agent.jnlp ubuntu@ec2-ip.region.compute.amazonaws.com
> ssh -i "<name>.pem" ubuntu@ec2-ip.region.compute.amazonaws.com

ubuntu > ls
agent.jar  jenkins-agent.jnlp
```

### Step 7:

- Connect to Jenkins node in the VM
- SSH into the test-server VM
- First update the VM: sudo apt-get update
- mkdir jenkins (to make the required jenkins directory)
- Run the command from the jenkins page which uses agent.jar to connect to the Jenkins node
- By doing this on this VM, it will have INFO: Connected
- You then switch over to another VM for the Git workflow

### Step 8:

- Connect to the same VM (test-server) on a different Terminal window
- SSH into the instance
- Update the packages
- Initialise git on the VM
```bash
sudo git init 
```

- Clone your repo on both the test-server
```
sudo git clone <your-github-repo>
```

- Modify the index.html file so you can use the Git workflow
- Once modified, follow the Git workflow:

```
sudo git add .
sudo git commit -m "Initial commit"
```
- Don’t push just yet - we need to connec Github to Jenkins via a Github webhook
- Follow these steps to get the webhook
    - On your Github repo, go to settings
    - Click on Webhooks on the left hand side
    - Add a webhook
    - Enter your Password
    - Your URL is your Jenkins URL (remember Jenkins URL is the IP of our main EC2 instance followed by the default Jenkins port 8080
    ```
    http://<main-ec2-ip>:8080/github-webhook
    ```
    - This format will be recognised as a payload URL by github
    - This ensures if there are changes made to Github (i.e. a git push), then it will trigger a build
    - We now create a test-job on Jenkins, call it “test-github-webhook”
    - Select Github project and paste the URL of your Github repo
    - Restrict where the project runs to your test-server node (this is where the builds will run
    - For source code management, select git and again paste your Github repo
    - For branches, select your ‘main’ branch - the default on Jenkins is master but this is the old naming mechanism, so change it to main
    - For build triggers, select Github hook trigger
    - Under build, select execute shell and add a command that will run if the build is successful (as an indication)
    - Save the job   

- Now go back to your VM terminal for the test-server and run the final git push step
```
sudo git push origin main
```

- This step will ask you to enter your Github credentials
    - Your username is the email associated with Gihub
    - Your password however is a token which you need to retrieve from Github
    - Go to Main settings on your Github account
    - Click on Developer setting right at the bottom of the left panel
    - Click on Personal access tokens and generate a new token
    - This will ask you to enter your Github password (your normal password)
    - Use the token generated and paste on the CLI from above
    - The push will then go through
- Ensure the push is gone through by refreshing your Github repo
- More importantly visit the Jenkins test-server node to see if the build was triggered and if it was successful

### Step 9: Workflow test from a different branch (not main)

- On the VM CLI, create a developer branch
```
sudo git checkout -b developer
```
- This will create and swtich to the ‘developer’ branch
- We now create a dockerfile to run the index.html website (this is given to us by the developer)
- The dockerfile contents are below:
```
FROM hshar/webapp # this is a pre-built container
ADD . /var/www/html # this is the directory the files should be stored
```

- Save this. NOTE: a dockerfile is just called ‘Dockerfile’
- By adding this, you now have to run the git workflow
```
sudo git add .
sudo git commit -m "Added Dockerfile"
```
- Before pushing, the job on Jenkins is configured to accept pushes from the main branch but not other branches, you can choose to add the devloper branch on the Job by configuring it on Jenkins
- Now push
```
sudo git push origin developer
```
- Enter username and Token from before
- This will trigger the build


### Step 10:

- Create a job, call it “build-website”
- Again add github project + URL
- Restrict node to test-server, add branch main and developer
- Build trigger enabled for Github
- Source code management, git and URL
- Finally add a command to be run on the build (this command will determine what to do with the existing dockerfile, i.e. run a container which has the index.html website)
```
sudo docker build /home/ubuntu/jenkins/<name-of-your-repo>/. -t test
sudo docker run -it -p 82:80 -d test
```
- Before making a push, to run these docker commands, docker must be installed on both VMs
- Run the command below to install docker:
```
sudo apt-get install docker.io
```
- This must be run on both

### Step 11: Make a push to the main branch to trigger the build in our new job

- To do this, acknowledge that we already pushed the changes from the developer branch (this only included the dockerfile)
- But now that we downloaded the dependencies for docker, we can create our container
- So we merge the developer branch with the main branch so the changes are present on main
```
sudo git checkout main # to switch back to main branch

sudo git merge developer # to merge the developer branch to the main branch
```
- We then push these changes to Github
```
sudo git add .
sudo git commit -m "Added dockerfile to main branch"
sudo git push origin main
```

- On push, enter credentials. Github email and token (from before)
- These changes will show on Github after refreshing
- There will also be a trigger on the build-website
- To test if the website is accessible, copy the public IP of the test-server instance and paste it on your browser
```
http://<test-server-ip>:82
```
- Success: The website should show ‘Hello World’ with the Github logo

### Step 12: For future builds 

- The port 82 is being used now by the docker container we created
- This will result in a failure if changes are made to the repo
- So we need to configure the build and in the execute shell command section we delete the docker container that already exists so that it deletes the container before applying the changes, so we only have one container for the job
```
sudo docker rm -f $(sudo docker ps -a -q)
sudo docker build /home/ubuntu/jenkins/<name-of-your-repo>/. -t test
sudo docker run -it -p 82:80 -d test
```
- This now removes the existing container (which is using port 82), and then recreates our container again on port 82