# **AWS Resource Cleanup Automation**

This project automates the cleanup of AWS resources (EC2 instances, VPCs, EKS clusters, and other services) when an alert email about exceeding the AWS Free Tier limit is received. The solution leverages Gmail, Google Apps Script, and GitHub Actions to trigger the cleanup script.

---

## **How It Works**

1. **AWS Alert Emails**: AWS sends an email to your Gmail account when you exceed free tier limits.
2. **Gmail Filter**: A Gmail filter tags these emails with the label `AWS Free Tier limit alert`.
3. **Google Apps Script**: Monitors for unread emails with the specific label and sends a webhook to GitHub Actions.
4. **GitHub Actions**: Executes the cleanup script to terminate or delete AWS resources.

---

## **Project Structure**

```plaintext
root/
├── .github/
│   ├── workflows/
│   │   └── aws-cleanup.yml  # GitHub Actions workflow file
├── aws_cleanup.sh       # AWS resource cleanup script
├── README.md                # Documentation
```

## **Setup Instructions**

### **Step 1: Configure Gmail**

1. Log in to your Gmail account.
2. Create a filter:
   - Search for emails containing subjects like `AWS Free Tier limit alert`.
   - Apply the label: **AWS Free Tier limit alert**.
3. Ensure AWS alert emails are correctly tagged with this label.


### **Step 2: Set Up Google Apps Script**

1. Go to [Google Apps Script](https://script.google.com/).
2. Create a new project and paste the script provided in the repository.
3. Replace `<owner>` and `<repo>` in the script with your GitHub username and repository name.
4. Add a trigger:
   - Set the function to `sendWebhookForAWSAlert`.
   - Use a time-driven trigger (e.g., every 5 minutes).


### **Step 3: Set Up GitHub Repository**

1. Create a GitHub repository.
2. Add the GitHub Actions workflow file (`aws-cleanup.yml`) in the `.github/workflows/` directory, which is available in the repository.
3. Add the cleanup script (`aws_cleanup.sh`) in your repository.
4. Commit and push the files to GitHub.


### **Step 4: Add GitHub Secrets**

In your GitHub repository:
1. Go to **Settings** → **Secrets and Variables** → **Actions** → **New repository secret**.
2. Add the following secrets:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`


### **Step 5: Test the Setup**

1. Send a test email to your Gmail that matches the filter criteria.
2. Verify that:
   - The email is tagged with the label.
   - Google Apps Script sends a webhook to GitHub.
   - GitHub Actions executes the cleanup script.

---

## **Features**

Deletes EC2 instances, VPCs (excluding the default one), EKS clusters, and associated resources from the regions I use frequently.
Fully automated workflow triggered by email alerts.
Cost-effective using free Gmail, Google Apps Script, and GitHub Actions.

The **`cleanup_log.txt`** file captures key actions performed during the AWS Cleanup workflow, including:
- Terminated EC2 instances
- Deleted VPCs
- Deleted EKS clusters and node groups

### Example Log Entry:
```text
Terminated EC2 instances: i-0c5289b1779c104cc
Deleted VPC: vpc-0195a6567c0bdba84 in region us-west-2
Cleanup completed at Sun Jan 12 17:42:44 UTC 2025

---

## **Limitations**
ghp_############niu2ThNd0AZaONApiT1FCeWxTYI2vY21Pubh
ghp_@@@@@@@@@@@@tBDiwtN2eJno9puQ6S783NVvPTRj3q45oln8
Free tiers for Gmail and GitHub may have usage limits.
