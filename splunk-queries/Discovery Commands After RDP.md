```
index=* (EventCode=4688 OR EventCode=1)
| eval process=coalesce(New_Process_Name, Image)
| eval command=coalesce(CommandLine, Process_Command_Line)
| search command="*whoami*" 
    OR command="*hostname*" 
    OR command="*ipconfig*" 
    OR command="*net user*" 
    OR command="*net localgroup*" 
    OR command="*quser*" 
    OR command="*tasklist*" 
    OR command="*net view*"
| table _time host user process ParentImage command
| sort - _time
```
<img width="1812" height="851" alt="image" src="https://github.com/user-attachments/assets/7d58088b-13ef-4b40-baa5-e57921d5ed05" />
