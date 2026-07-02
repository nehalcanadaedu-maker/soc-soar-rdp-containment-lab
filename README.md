# End-to-End SOC/SOAR Automation Lab: Unauthorized RDP Login Detection & AD Containment

## 1. Project Overview

This project demonstrates an end-to-end SOC/SOAR automation workflow for detecting, enriching, reviewing, and responding to unauthorized Remote Desktop Protocol (RDP) logins in an Active Directory lab environment.

The lab simulates a real-world security operations workflow where Splunk detects a successful RDP login from a source IP address that is not part of the approved access list. The alert is forwarded to Shuffle SOAR using a webhook. Shuffle then enriches the source IP using AbuseIPDB threat intelligence and sends the SOC analyst an approval request containing the alert details, IP reputation data, MITRE ATT&CK mapping, risk assessment, and triage checklist.

If the analyst approves containment, Shuffle triggers a PowerShell-based Active Directory response workflow to disable the affected domain user account. After the response action runs, the workflow verifies the account status and generates a final Slack incident report confirming the containment result.

If the analyst does not approve containment, the workflow does not perform any disruptive action. Instead, Shuffle generates a no-action Slack incident report showing that the event was reviewed, containment was rejected, and the alert should remain under monitoring or manual investigation.

This project was designed to demonstrate the full SOC incident response lifecycle:

Detection → Enrichment → Analyst Approval → Containment Decision → Verification → Incident Reporting

## 2. Project Objective

The objective of this project was to build a realistic SOC automation workflow that goes beyond basic alerting. Instead of only detecting an unauthorized RDP login, the workflow enriches the alert, provides useful triage context to the analyst, requires approval before containment, performs the response action when approved, verifies the result, and generates a final incident report.

The project was designed to simulate how a SOC team can combine SIEM detection, SOAR automation, threat intelligence enrichment, analyst decision-making, and Active Directory containment in one workflow.

The main goals were:

- Detect successful RDP logins from unauthorized source IP addresses.
- Forward Splunk alerts to Shuffle SOAR using webhooks.
- Enrich the source IP with AbuseIPDB threat intelligence.
- Provide the SOC analyst with alert details, IP reputation, MITRE ATT&CK mapping, risk assessment, and triage context.
- Require analyst approval before taking containment action.
- Disable the affected Active Directory user account using a PowerShell-based response workflow when containment is approved.
- Verify whether the account was successfully disabled.
- Generate final Slack incident reports for both approved containment and rejected/no-action decisions.
- Document the final outcome so the SOC team can clearly see what was detected, what decision was made, what action was taken, and whether containment was verified.

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

The lab was hosted in a Vultr cloud environment using Windows Server and Ubuntu virtual machines to simulate a small enterprise SOC network. The Windows Domain Controller and the domain-joined target server were connected within the same lab environment, while the Splunk server acted as the centralized SIEM platform.

Windows Security logs were forwarded to Splunk using the Splunk Universal Forwarder. Splunk monitored authentication activity, including successful RDP logons, and generated an alert when a successful RDP login was detected from a source IP address outside the approved access list.

After the alert triggered, Splunk forwarded the event details to Shuffle SOAR using a webhook. Shuffle handled the enrichment, analyst approval process, Active Directory containment action, verification step, and final Slack incident report generation.

## 4. SOAR Workflow Diagram

The Shuffle SOAR workflow receives alerts from Splunk through a webhook and acts as the automation layer for the incident response process. After receiving the alert, Shuffle sends an initial Slack notification to the SOC channel, enriches the source IP address using AbuseIPDB, sends an analyst approval email, and then routes the workflow based on the analyst decision.

If the analyst approves containment, Shuffle triggers the PowerShell-based Active Directory response workflow to disable the affected user account. After the disable action runs, the workflow verifies the account status and generates a final Slack incident report showing the detection details, enrichment results, analyst decision, containment action, verification status, and final outcome.

If the analyst does not approve containment, Shuffle does not perform any disruptive action. Instead, it generates a no-action Slack incident report showing that the alert was reviewed, containment was rejected, and the event should remain under monitoring or manual investigation.

<img width="1157" height="496" alt="image" src="https://github.com/user-attachments/assets/2c8c8e5a-f4e9-4188-8c12-cbe4b1540557" />

### Workflow Steps

1. Splunk detects a successful RDP login from an unauthorized source IP.
2. Splunk sends the alert details to Shuffle SOAR using a webhook.
3. Shuffle sends an initial Slack notification to the SOC channel.
4. Shuffle queries AbuseIPDB for source IP reputation enrichment.
5. Shuffle sends an analyst approval email containing alert details, IP reputation, MITRE ATT&CK mapping, risk assessment, and triage context.
6. The analyst approves or rejects the containment action.
7. If approved, Shuffle calls the PowerShell Active Directory response workflow to disable the affected user account.
8. Shuffle verifies the containment result after the disable action.
9. Shuffle generates a final Slack incident report for approved containment.
10. If rejected, Shuffle skips containment and generates a no-action Slack incident report.

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

<img width="1082" height="183" alt="image" src="https://github.com/user-attachments/assets/2fa38904-cf3f-46f3-be9f-073ea477c4c0" />


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

<img width="1397" height="623" alt="image" src="https://github.com/user-attachments/assets/2b4d5c7a-1051-4c35-8ecc-53f24aae9292" />
<img width="1787" height="486" alt="image" src="https://github.com/user-attachments/assets/0c199e22-1005-4359-85a2-7e52251e9406" />


## 9. Active Directory Containment Action

If the SOC analyst approves containment, Shuffle triggers a PowerShell-based Active Directory response workflow. The response action disables the affected domain user account to prevent further unauthorized access.

In this lab, the target user account was `npatel`.

**PowerShell Response API**

Shuffle sends an HTTP POST request to a PowerShell listener running on the Domain Controller.

http://<DOMAIN_CONTROLLER_PUBLIC_IP>:8085/disable/

## 10. Incident Report Generation

After the analyst decision is completed, the SOAR workflow generates a final incident-style Slack report for the SOC channel. This report summarizes the detection, enrichment, analyst decision, containment action, verification result, and final outcome.

The workflow supports two final report outcomes:

1. **Containment Completed Report**
   - Generated when the analyst approves containment.
   - Includes the Splunk alert name, detection time, affected user, host, source IP, AbuseIPDB enrichment, MITRE ATT&CK mapping, containment action, PowerShell response result, and verification status.
   - Confirms whether the Active Directory account was successfully disabled.

2. **No Action / Monitoring Report**
   - Generated when the analyst rejects containment.
   - Includes the original alert details, enrichment context, MITRE ATT&CK mapping, analyst decision, and final monitoring status.
   - Confirms that no disruptive containment action was performed.

This reporting step helps simulate a real SOC workflow where the team receives a clear post-decision summary instead of only seeing whether an automation succeeded or failed.

## 11. MITRE ATT&CK Mapping

The unauthorized RDP login detection was mapped to MITRE ATT&CK techniques to show how the observed behavior may align with real adversary activity.

### Mapped Techniques

| MITRE ID | Technique | Reason |
|---|---|---|
| T1021.001 | Remote Services: Remote Desktop Protocol | The detected activity involved a successful RDP login to a Windows host. |
| T1078 | Valid Accounts | The login used a legitimate Active Directory user account, which could indicate stolen or misused credentials. |

### Why This Mapping Matters

This alert maps to `T1021.001 - Remote Services: Remote Desktop Protocol` because the access method was RDP. Attackers often use RDP for remote access and lateral movement after obtaining valid credentials.

This alert also maps to `T1078 - Valid Accounts` because the activity involved successful authentication using a real domain user account. If the credentials were stolen, guessed, or misused, the attacker could access systems while appearing as a normal user.

### SOC Context

```text
T1021.001 = How the user accessed the system: RDP
T1078     = What was used to authenticate: Valid AD credentials
```

## 13. False Positive Considerations

Not every successful RDP login from an unfamiliar IP address is malicious. A SOC analyst should review the alert context before approving containment to avoid disabling legitimate user accounts.

### Possible False Positives

| Scenario | Explanation |
|---|---|
| Approved VPN IP not allowlisted | A legitimate user may connect from a company VPN IP that has not been added to the approved list. |
| Admin jump box activity | Administrators may use specific jump servers or remote access systems for maintenance. |
| User working from a new location | A user may connect from a different network, city, or ISP. |
| Clean AbuseIPDB score | A clean reputation score does not prove the activity is safe, but it may lower confidence that the IP is known malicious. |
| Expected after-hours work | Some users may have legitimate business reasons to access systems outside normal hours. |

### Analyst Review Notes

Before disabling the account, the analyst should confirm whether the activity is expected. The workflow requires approval before containment so that legitimate access is not disrupted automatically.

### Recommended Improvements

- Maintain an allowlist of approved VPN, admin, and office IP ranges.
- Add user behavior baselines for normal RDP activity.
- Include recent failed login counts before the successful login.
- Add asset criticality to understand the risk of the destination host.
- Add privileged account checks before taking containment action.

## 14. Production Hardening Considerations

This project was built in a controlled lab environment. In a production environment, additional security controls would be required before allowing a SOAR workflow to disable Active Directory accounts.

### Recommended Hardening

| Area | Recommendation |
|---|---|
| API Security | Use HTTPS instead of HTTP for the PowerShell response API. |
| Network Access | Restrict the response API so only the SOAR server can reach it. |
| Authentication | Store API tokens securely and rotate them regularly. |
| Protected Accounts | Exclude Domain Admins, service accounts, and critical accounts from automatic disablement. |
| Approval Control | Require analyst approval before containment actions. |
| Logging | Log every containment request, approval decision, and response result. |
| Change Control | Integrate containment actions with ticketing or incident management systems. |
| Error Handling | Send failure notifications if account disablement or verification fails. |

### Production Notes

The PowerShell response API should not be publicly exposed in a real environment. It should be protected using firewall rules, authentication, HTTPS, and strong logging. Containment actions should also include safeguards to prevent accidental disablement of privileged or business-critical accounts.

## 15. Lessons Learned

This project helped demonstrate how multiple SOC functions work together in a realistic detection and response workflow. Instead of stopping at alert generation, the workflow continued through enrichment, analyst approval, containment, and verification.

### Key Takeaways

- Learned how Windows Security Event ID `4624` and Logon Type `10` can be used to detect successful RDP authentication.
- Practiced building Splunk SPL detection logic for suspicious authentication activity.
- Integrated Splunk alerts with Shuffle SOAR using webhooks.
- Added AbuseIPDB enrichment to provide IP reputation context before analyst approval.
- Used Slack and email notifications to simulate SOC communication and approval workflows.
- Implemented a PowerShell-based Active Directory containment action to disable affected user accounts.
- Verified containment by checking the final AD account status after the response action.
- Learned the importance of analyst approval, false-positive review, and safe automation before taking disruptive actions.

### Main SOC Lesson

The biggest lesson from this project was that a good SOC workflow is not only about detecting suspicious activity. A complete workflow should provide context, support analyst decision-making, perform safe containment, and verify the final outcome.

## 16. Future Improvements

This project currently focuses on unauthorized RDP login detection, alert enrichment, analyst approval, Active Directory containment, and final verification. The workflow can be expanded further to support additional SOC use cases and improve detection accuracy.



