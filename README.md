# End-to-End SOC/SOAR Automation Lab: Unauthorized RDP Login Detection & AD Containment

## 🎥 Project Demo Video
[![SOC/SOAR Automation Lab](https://img.youtube.com/vi/V5eVrKFt72M/0.jpg)](https://youtu.be/V5eVrKFt72M)

## 1. Project Overview

This project demonstrates an end‑to‑end SOC/SOAR automation workflow for detecting, enriching, reviewing, and responding to unauthorized Remote Desktop Protocol (RDP) logins in an Active Directory lab environment.

Splunk detects a successful RDP login from an IP address outside the approved access list and forwards the alert to Shuffle SOAR via webhook. Shuffle enriches the source IP using AbuseIPDB threat intelligence and sends the SOC analyst an approval request containing alert details, IP reputation, MITRE ATT&CK mapping, risk assessment, and a triage checklist.

If the analyst approves containment, Shuffle triggers a PowerShell‑based Active Directory workflow that disables the affected domain user account. The workflow then verifies the account status and generates a final Slack incident report confirming the containment result.

If containment is rejected, Shuffle generates a no‑action Slack report showing that the alert was reviewed, rejected, and should remain under monitoring.

The project demonstrates the full SOC incident response lifecycle:

**Detection → Enrichment → Analyst Approval → Containment Decision → Verification → Incident Reporting**

Additionally, the workflow includes **full audit‑grade logging** from Shuffle → Splunk via HEC, tracking true/false status for all major workflow steps including enrichment, Jira ticketing, user decision, AD disable action, Slack reporting, and alert status.

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
- Log every major workflow step to Splunk via HEC for audit‑grade tracking. Tracks enrichment, Jira ticketing, user approval, AD disable action, Slack reports, and alert status

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

Once the alert fired, Splunk forwarded the event to Shuffle SOAR via webhook. Shuffle handled enrichment, analyst approval, Active Directory containment, verification, Slack reporting, and audit‑grade workflow logging back into Splunk via HEC.

## 4. SOAR Workflow Diagram

The Shuffle SOAR workflow acts as the automation engine for the entire incident response process. After Splunk sends an alert through a webhook, Shuffle begins a multi‑step workflow that mirrors a real SOC playbook.

### 🔄 Workflow Summary

1. **Splunk Alert Triggered**  
   A successful RDP login from an unauthorized IP fires the detection.

2. **Slack Alert Notification**  
   Shuffle immediately sends a Slack message to the SOC channel with the alert details.

3. **AbuseIPDB Enrichment**  
   The source IP is checked against AbuseIPDB to gather threat intelligence and reputation data.

4. **Jira incident ticket is created**

5. **User‑Action (Analyst Decision)**  
   Shuffle sends an approval prompt asking whether the affected AD user should be disabled.

6. **Conditional Workflow Branching**
   - **If Approved → Containment Path**
     - PowerShell API disables the AD user 
     - Final Slack report: **Contained**
   - **If Rejected → No‑Action Path**
     - No containment is performed  
     - Final Slack report: **Rejected / Monitoring**

7. **Audit‑Grade Logging to Splunk (HEC)**  
   Every major step—enrichment, user decision, Jira ticketing, AD disable action, Slack reports—is logged back into Splunk with true/false status for full workflow traceability.

<img width="1446" height="680" alt="image" src="https://github.com/user-attachments/assets/0c860d3e-7988-49e3-a4e6-f98301d1f158" />


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


## 8. Jira Incident Ticket Creation  

After the AbuseIPDB enrichment step, Shuffle automatically creates a Jira incident ticket under project **KAN** to formally record and track the event.  

### 🧾 Ticket Details  
| Field | Description |
|-------|--------------|
| **Project Key** | `KAN` |
| **Issue Type** | `Task` |
| **Summary** | `Unauthorized RDP Login – $exec.result.user from $exec.result.Source_Network_Address` |
| **Description Sections** | |
| • **Incident Summary** | Successful RDP login detected from an unauthorized IP. |
| • **Alert Details** | Includes alert name, detection time, user, host, source IP, logon type, detection type, severity. |
| • **AbuseIPDB Enrichment** | Confidence score, country, ISP, total reports, last reported time. |
| • **MITRE ATT&CK Mapping** | Tactics: Initial Access / Lateral Movement; Techniques: T1021.001 (RDP), T1078 (Valid Accounts). |
| • **Analyst Triage Checklist** | Step‑by‑step validation items (IP approval, user behavior, login time, failed attempts, privilege level, host expectation). |
| • **Recommended Action** | Disable AD account only if login is confirmed unauthorized or suspicious. |
| • **Current Ticket Status** | Awaiting analyst approval. |

This ensures every alert is documented, traceable, and auditable within the SOC workflow.  

<img width="1913" height="962" alt="image" src="https://github.com/user-attachments/assets/1bdc06d7-ccf9-4380-97d2-4c6620f55090" />



## 9. Analyst Approval Email

After the Jira Incident Ticket Creation step, Shuffle sends an approval email to the SOC analyst. This email contains the original Splunk alert details, IP reputation enrichment, MITRE ATT&CK mapping, risk assessment, and triage checklist.

The purpose of this step is to make sure containment is not performed automatically without analyst review. The analyst can review the context and decide whether the affected Active Directory account should be disabled.

### Approval Email Content

<img width="767" height="692" alt="image" src="https://github.com/user-attachments/assets/2323fc48-df6a-40c6-bb09-72776a87f8f6" />

## 10. Active Directory Containment Action

If the SOC analyst approves containment, Shuffle triggers a PowerShell-based Active Directory response workflow. The response action disables the affected domain user account to prevent further unauthorized access.

In this lab, the target user account was `npatel`.

**PowerShell Response API**

Shuffle sends an HTTP POST request to a PowerShell listener running on the Domain Controller.

http://<DOMAIN_CONTROLLER_PUBLIC_IP>:8085/disable/

## 11. Incident Report Generation

After the analyst decision is completed, the SOAR workflow generates a final incident-style Slack report for the SOC channel. This report summarizes the detection, enrichment, analyst decision, containment action, verification result, and final outcome.

The workflow supports two final report outcomes:

1. **Containment Completed Report**
   - Generated when the analyst approves containment.
   - Includes the Splunk alert name, detection time, affected user, host, source IP, AbuseIPDB enrichment, MITRE ATT&CK mapping, containment action, PowerShell response result, and verification status.
   - Confirms whether the Active Directory account was successfully disabled.

<img width="986" height="571" alt="image" src="https://github.com/user-attachments/assets/b41e8940-2128-4e83-b047-87f26eacc5b8" />
   
<img width="1377" height="568" alt="image" src="https://github.com/user-attachments/assets/40df6134-7e22-4811-89e0-5acf2e67b046" />


2. **No Action / Monitoring Report**
   - Generated when the analyst rejects containment.
   - Includes the original alert details, enrichment context, MITRE ATT&CK mapping, analyst decision, and final monitoring status.
   - Confirms that no disruptive containment action was performed.

<img width="1136" height="456" alt="image" src="https://github.com/user-attachments/assets/201e71e0-b82e-469a-b113-f704799af050" />
     
<img width="1350" height="557" alt="image" src="https://github.com/user-attachments/assets/e5ea04a7-cc08-41f2-8425-b326476f2228" />

This reporting step helps simulate a real SOC workflow where the team receives a clear post-decision summary instead of only seeing whether an automation succeeded or failed.

**Audit-Grade Workflow Logging**

The workflow sends full audit-grade logs from Shuffle SOAR to Splunk through HTTP Event Collector (HEC).

Each major workflow step records a success or failure value, allowing analysts to verify whether the automation completed correctly and quickly identify failed actions



## 12. MITRE ATT&CK Mapping

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



