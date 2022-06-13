
# Ceros Devops Code Challenge

The Following steps was taken to complete the different tasks.
1. The repo was forked and cloned to my local machine
2. Make sure AWS cli is downloaded and configured with an AWS profile on the local machine using the terminal.
3. Test configuration by creating an s3 using the code below:
```
aws s3api create-bucket --bucket terraformstatebucket0485
```
where `terraformstatebucket0485` is the unique bucket name that would be created.

4. Create `backend.tf` file with the following code:
```
terraform {
  required_version = ">=0.14.4"
  backend "s3" {
    region  = "us-east-1"
    profile = "default"
    key     = "terraformstatefile"
    bucket  = "terraformstatebucket0485"
  }
}
```
This would enable your statefile to be stored in an s3 bucket for safe keeping incase of a computer crash or failure.

5. Followed the instructions in the usage.md file and loaded the game successfully! Image of runing game below.

## Loaded Game!

![App Screenshot](/loadedgame.png)

