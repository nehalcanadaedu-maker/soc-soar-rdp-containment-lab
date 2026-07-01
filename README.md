# End-to-End SOC/SOAR Automation Lab: Unauthorized RDP Login Detection & AD Containment

## 1. Project Overview

This project demonstrates an end-to-end SOC/SOAR automation workflow for detecting and responding to unauthorized Remote Desktop Protocol (RDP) logins in an Active Directory lab environment.

The lab simulates a real-world security operations workflow where Splunk detects a successful RDP login from an unauthorized source IP address. The alert is sent to Shuffle SOAR, where the source IP is enriched using AbuseIPDB threat intelligence. The SOC analyst then receives an approval request containing alert details, IP reputation data, MITRE ATT&CK mapping, risk assessment, and triage context.

If the analyst approves containment, Shuffle triggers a PowerShell-based Active Directory response workflow to disable the affected user account. The workflow then verifies the account status and sends a final Slack notification confirming whether containment was successful. If the analyst does not approve containment, a no-action Slack notification is sent instead.

This project was designed to show the full SOC incident response lifecycle:

Detection → Enrichment → Analyst Approval → Containment → Verification

## 2. Project Objective

The objective of this project was to build a realistic SOC automation workflow that goes beyond basic alerting. Instead of only detecting an unauthorized RDP login, the workflow enriches the alert, provides context to the analyst, requires approval before containment, performs the response action, and verifies the final result.

The main goals were:

- Detect successful RDP logins from unauthorized source IP addresses.
- Forward Splunk alerts to Shuffle SOAR using webhooks.
- Enrich the source IP with AbuseIPDB threat intelligence.
- Provide the SOC analyst with alert details, IP reputation, MITRE ATT&CK mapping, risk assessment, and triage context.
- Require analyst approval before taking containment action.
- Disable the affected Active Directory user account using a PowerShell-based response workflow.
- Verify whether the account was successfully disabled.
- Send final Slack notifications for both approved containment and no-action decisions.

  ## 3. Lab Environment

The lab was deployed on Vultr using three virtual machines to simulate an enterprise SOC environment with Active Directory, centralized logging, and SOAR-based response.

### Virtual Machines

| Hostname | Operating System | Role | Network |
|---|---|---|---|
| nehal-ADDC01 | Windows Server 2025 Standard | Active Directory Domain Controller | Public IP + Vultr VPC |
| Target-Windows-Server | Windows Server 2025 Standard | Domain-joined target machine for RDP testing | Public IP + Vultr VPC |
| nehal-splunk | Ubuntu 22.04 | Splunk Enterprise SIEM server | Public IP + Vultr VPC |

### Domain Information

| Item | Value |
|---|---|
| Domain | nehal.local |
| Test Domain User | npatel |
| Log Source | Windows Security Event Logs |
| SIEM Index | nehal-ad |
| Detection Use Case | Unauthorized RDP Login |

### Network Design

The Windows servers and Splunk server were hosted in the same Vultr cloud lab environment. Windows Security logs from the Domain Controller were forwarded to Splunk using the Splunk Universal Forwarder. Splunk generated alerts for suspicious RDP activity and forwarded those alerts to Shuffle SOAR for enrichment, analyst approval, and response automation.

## 4. SOAR Workflow Diagram

The Shuffle SOAR workflow receives alerts from Splunk, sends an initial Slack notification, enriches the source IP using AbuseIPDB, sends an analyst approval email, and then routes the workflow based on the analyst decision.

If the analyst approves containment, Shuffle triggers the PowerShell-based Active Directory response workflow to disable the affected user account and sends a final Slack confirmation. If the analyst does not approve containment, Shuffle sends a no-action Slack notification.

![Shuffle SOAR Workflow](images/shuffle-workflow.png)

<img width="1066" height="531" alt="image" src="https://github.com/user-attachments/assets/a5f6c606-3d71-472a-b35b-bce04bae667c" />

### Workflow Steps

1. Splunk detects a successful RDP login from an unauthorized source IP.
2. Splunk sends the alert to Shuffle using a webhook.
3. Shuffle sends an initial Slack notification to the SOC channel.
4. Shuffle queries AbuseIPDB for source IP reputation enrichment.
5. Shuffle sends an analyst approval email containing alert details, IP reputation, MITRE ATT&CK mapping, risk assessment, and triage context.
6. If approved, Shuffle calls the PowerShell Active Directory response workflow to disable the affected user account.
7. Shuffle verifies the containment result and sends a final Slack status notification.
8. If not approved, Shuffle sends a no-action Slack notification.

## 5. Detection Logic

The Splunk detection was created to identify successful Remote Desktop Protocol (RDP) logins from unauthorized source IP addresses. In Windows Security logs, successful logons are recorded with Event ID `4624`. For RDP activity, Logon Type `10` represents a Remote Interactive logon.

This detection excludes an approved source IP address and alerts when a successful RDP login occurs from any other source IP.

### Detection Details

| Field | Value |
|---|---|
| Event ID | 4624 |
| Logon Type | 10 |
| Activity | Successful RDP Login |
| Target User | npatel |
| Source IP Logic | Excludes approved IP address |
| Data Source | Windows Security Logs |
| SIEM | Splunk Enterprise |
| Index | nehal-ad |

### Splunk SPL Query

<img width="1908" height="527" alt="image" src="https://github.com/user-attachments/assets/d5b2c461-7e09-48f8-b056-85d06a196c1f" />

## 6. Slack Alert Notification

After Splunk detects a successful RDP login from an unauthorized source IP address, the alert is sent to Shuffle SOAR using a webhook. Shuffle then sends an initial Slack notification to the SOC channel.

The purpose of the Slack message is to quickly notify the SOC team that suspicious RDP activity was detected and that further enrichment and analyst approval are required.

### Slack Alert Message

<img width="781" height="180" alt="image" src="https://github.com/user-attachments/assets/5a0baf8f-58c8-4a51-b1d0-0fc83a343c6e" />

## 7. AbuseIPDB IP Reputation Enrichment

After the initial Slack alert is sent, Shuffle performs an IP reputation check against AbuseIPDB using the source IP address from the Splunk alert.

The purpose of this enrichment step is to give the SOC analyst additional threat intelligence before deciding whether to approve containment. This helps avoid making a response decision based only on the login event.

### Enrichment Workflow

```text
Splunk Alert
      ↓
Slack Alert Notification
      ↓
AbuseIPDB API Check
      ↓
Analyst Approval Email
```

## 8. Analyst Approval Email

After the AbuseIPDB enrichment step, Shuffle sends an approval email to the SOC analyst. This email contains the original Splunk alert details, IP reputation enrichment, MITRE ATT&CK mapping, risk assessment, and triage checklist.

The purpose of this step is to make sure containment is not performed automatically without analyst review. The analyst can review the context and decide whether the affected Active Directory account should be disabled.

### Approval Email Content

<img width="595" height="777" alt="image" src="https://github.com/user-attachments/assets/1696fcf0-67f9-434c-adbe-cb0dda6900d9" />

## 9. Active Directory Containment Action

If the SOC analyst approves containment, Shuffle triggers a PowerShell-based Active Directory response workflow. The response action disables the affected domain user account to prevent further unauthorized access.

In this lab, the target user account was `npatel`.

**PowerShell Response API**

Shuffle sends an HTTP POST request to a PowerShell listener running on the Domain Controller.

http://<DOMAIN_CONTROLLER_PUBLIC_IP>:8085/disable/

## 10. Final Slack Notifications

After the analyst decision and containment workflow, Shuffle sends a final Slack notification to the SOC channel. This gives the team visibility into whether the response action was completed or whether no containment action was taken.

The workflow has two possible final outcomes:

1. Containment approved and AD account disabled.

<img width="623" height="321" alt="image" src="https://github.com/user-attachments/assets/cbd919db-3dbf-42f4-b5b2-38ad60357ea9" />

3. Containment not approved and no action taken.

<img width="755" height="275" alt="image" src="https://github.com/user-attachments/assets/5489f5e2-d53e-47ce-bdaf-47b09afa230c" />









