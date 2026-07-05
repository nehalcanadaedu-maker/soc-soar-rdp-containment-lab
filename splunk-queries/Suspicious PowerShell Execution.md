```
index="nehal-ad" EventCode=1 (Image="*powershell.exe" OR Image="*pwsh.exe")
| eval cmd=lower(CommandLine)
| where like(cmd,"%encodedcommand%") OR like(cmd,"%-enc%") OR like(cmd,"%bypass%") OR like(cmd,"%nop%") OR like(cmd,"%hidden%") OR like(cmd,"%iex%") OR like(cmd,"%invoke%") OR like(cmd,"%downloadstring%") OR like(cmd,"%webclient%")
| eval event_time=strftime(_time,"%m/%d/%Y %I:%M:%S.%3N %p")
| eval user=replace(coalesce(User,user,Account_Name,"npatel"),"^.*\\\\","")
| eval Image=replace(Image,"\\\\","/"), ParentImage=replace(ParentImage,"\\\\","/")
| table event_time ComputerName user Image ParentImage CommandLine
| sort - event_time
```

<img width="1917" height="870" alt="image" src="https://github.com/user-attachments/assets/9e5dc0d4-9722-433a-8f19-b53bfa92b88b" />
