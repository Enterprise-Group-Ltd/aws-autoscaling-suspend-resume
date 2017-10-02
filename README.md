# EGL AWS Autoscaling Suspend / Resume Utility

This utility suspends or resumes AWS Autoscaling groups. 

This utility provides Autoscaling suspend/resume functionality unavailable in the AWS console or directly via the AWS CLI API. 

## Getting Started

1. Instantiate a local or EC2 Linux instance
2. Install or update the AWS CLI utilities (these are pre-installed on AWS EC2 Linux instances) 
3. Create an AWS CLI profile that includes the required IAM permissions 
4. Install the [bash](https://www.gnu.org/software/bash/) shell (bash is included in most distributions and is pre-installed on AWS EC2 Linux instances)
5. Install [jq](https://github.com/stedolan/jq) 
6. Download this utility script or create a local copy and run it on the local or EC2 linux instance 

## Prerequisites

* [bash](https://www.gnu.org/software/bash/) - Linux shell 
* [jq](https://github.com/stedolan/jq) - JSON wrangler
* [AWS CLI](https://aws.amazon.com/cli/) - command line utilities (pre-installed on AWS AMIs) 
- AWS CLI profile with IAM permissions for the following AWS CLI commands:  
  - autoscaling describe-auto-scaling-groups  
  - autoscaling suspend-processes  
  - autoscaling resume-processes    
  - sts get-caller-identity  (used to pull the AWS account number for the report)


## Deployment

To execute the utility:
  `$ bash ./aws-asg-suspend-resume.sh`  

To execute the utility directly:
  1. Set the execute flag: `$ chmod +x aws-asg-suspend-resume.sh`
  2. `$ ./aws-asg-suspend-resume.sh`    

## Output

This utility produces a summary report. 

This utility can produce a log (with the -g y parameter) and each log can be run in console verbose mode (with the -b y parameter). 

## Contributing

Please read [CONTRIBUTING.md](https://gist.github.com/PurpleBooth/b24679402957c63ec426) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. 

## Authors

* **Douglas Hackney** - [dhackney](https://github.com/dhackney)

## License

This project is licensed under the MIT License - see the [LICENSE.md](https://github.com/Enterprise-Group-Ltd/egl-utilities/blob/master/LICENSE) file for details

## Acknowledgments

* [Progress bar](https://stackoverflow.com/questions/238073/how-to-add-a-progress-bar-to-a-shell-script)  
* [Dynamic headers fprint](https://stackoverflow.com/questions/5799303/print-a-character-repeatedly-in-bash)
* [Menu](https://stackoverflow.com/questions/30182086/how-to-use-goto-statement-in-shell-script)
* Countless other jq and bash/shell Q&A, posts, etc. from various sources  
