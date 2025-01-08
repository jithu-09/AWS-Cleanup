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

---

## **Features**

Deletes EC2 instances, VPCs (excluding the default one), EKS clusters, and associated resources.
Fully automated workflow triggered by email alerts.
Cost-effective using free Gmail, Google Apps Script, and GitHub Actions.

---

---

## **Limitations**

Free tiers for Gmail and GitHub may have usage limits.
Resources in AWS regions other than the configured one need manual updates in the script.

---
