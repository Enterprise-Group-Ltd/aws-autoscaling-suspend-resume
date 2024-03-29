# EGL AWS Autoscaling Suspend / Resume Utility

This utility suspends or resumes AWS Autoscaling groups. 

This utility provides Autoscaling suspend/resume functionality unavailable in the AWS console or directly via the AWS CLI API. 

This utility can: 

* Suspend or resume one Autoscaling Group
* Suspend or resume a set of like-named Autoscaling Groups
* Suspend or resume all Autoscaling Groups

This utility produces a summary report listing the suspended/resumed Autoscaling Groups. 

## Getting Started

1. Instantiate a local or EC2 Linux instance
2. Install or update the AWS CLI utilities
    * The AWS CLI utilities are pre-installed on AWS EC2 Linux instances
    * To update on an AWS EC2 instance: `$ sudo pip install --upgrade awscli` 
3. Create an AWS CLI named profile that includes the required IAM permissions 
    * See the "[Prerequisites](#prerequisites)" section for the required IAM permissions
    * To create an AWS CLI named profile: `$ aws configure --profile MyProfileName`
    * AWS CLI named profile documentation is here: [Named Profiles](http://docs.aws.amazon.com/cli/latest/userguide/cli-multiple-profiles.html)
4. Install the [bash](https://www.gnu.org/software/bash/) shell
    * The bash shell is included in most distributions and is pre-installed on AWS EC2 Linux instances
5. Install [jq](https://github.com/stedolan/jq) 
    * To install jq on AWS EC2: `$ sudo yum install jq -y`
6. Download this utility script or create a local copy and run it on the local or EC2 Linux instance
    * Example: `$ bash ./aws-asg-suspend-resume.sh -a s -n all -p MyProfileName`  

## [Prerequisites](#prerequisites)

* [bash](https://www.gnu.org/software/bash/) - Linux shell 
* [jq](https://github.com/stedolan/jq) - JSON wrangler
* [AWS CLI](https://aws.amazon.com/cli/) - command line utilities (pre-installed on AWS AMIs) 
* AWS CLI profile with IAM permissions for the following AWS CLI commands:  
  * autoscaling describe-auto-scaling-groups  
  * autoscaling suspend-processes  
  * autoscaling resume-processes    
  * sts get-caller-identity  (used to pull the AWS account number for the report)


## Deployment

To execute the utility:

  * Example: `$ bash ./aws-asg-suspend-resume.sh`  

To directly execute the utility:  

1. Set the execute flag: `$ chmod +x aws-asg-suspend-resume.sh`
2. Execute the utility  
    * Example: `$ ./aws-asg-suspend-resume.sh -a s -n all -p MyProfileName`    

## Output

* Summary report 
* Debug log (execute with the `-g y` parameter)  
  * Example: `$ bash ./aws-asg-suspend-resume.sh -a s -n all -p MyProfileName -g y`  
* Console verbose mode (execute with the `-b y` parameter)  
  * Example: `$ bash ./aws-asg-suspend-resume.sh -a s -n all -p MyProfileName -b y`  

## Contributing

Please read [CONTRIBUTING.md](https://github.com/Enterprise-Group-Ltd/aws-autoscaling-suspend-resume/blob/master/CONTRIBUTING.md) for  the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. 

## Authors

* **Douglas Hackney** - [dhackney](https://github.com/dhackney)

## License

This project is licensed under the MIT License - see the [LICENSE.md](https://github.com/Enterprise-Group-Ltd/aws-autoscaling-suspend-resume/blob/master/LICENSE) file for details

## Acknowledgments

* [Progress bar](https://stackoverflow.com/questions/238073/how-to-add-a-progress-bar-to-a-shell-script)  
* [Dynamic headers fprint](https://stackoverflow.com/questions/5799303/print-a-character-repeatedly-in-bash)
* [Menu](https://stackoverflow.com/questions/30182086/how-to-use-goto-statement-in-shell-script)
* Countless other jq and bash/shell man pages, Q&A, posts, examples, tutorials, etc. from various sources  

