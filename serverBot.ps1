#make sure there is a directory to store secure creds in
if(!(Test-Path -Path C:\temp )){
    New-Item -ItemType Directory -Force -Path C:\temp
}

#receive creds from user and store as variable
#$username = Read-Host -Prompt "Please enter the email address you want to send from:"
$username = "youraccount@domain.com"

#Create a file to store your email password
if(!(Test-Path -Path C:\temp\securestring.txt )){
    read-host -assecurestring "Please enter your password" | convertfrom-securestring | out-file C:\temp\securestring.txt
}
$password = cat C:\temp\securestring.txt | convertto-securestring
$mycreds = new-object -typename System.Management.Automation.PSCredential `
         -argumentlist $username, $password

$emailsent = 'na'
#infinite loop for calling connect function
while(1)
{
    $a = Get-Date
    $hour = $a.Hour
    $minute = $a.Minute
    if ($hour -eq '7' -And $Minute -gt 44) {
        Send-MailMessage -To "recipient1@domain.com" -Cc "recipient2@domain.com" -SmtpServer "smtp.office365.com" -Credential $mycreds -UseSsl "Serverbot is running :)" -Port "587" -Body "The script is still running" -From $username -BodyAsHtml
    }
    $webrequest = (Invoke-WebRequest -URI "https://monitoredserver.com" -UseBasicParsing -TimeoutSec 60)
    $statuscode = $webrequest.StatusCode
    write-host $a
    write-host $statuscode
    $content = $webrequest.content
    $siteup = $content.tostring() -split "[`r`n]" | select-string -Pattern "generous"

    #if status code is not 200, send an email to support or do nothing if email has been sent
    if ($statuscode -ne 200) {
        if ($emailsent -ne 'True') {
            Send-MailMessage -To "recipient1@domain.com" -Cc "recipient2@domain.com","recipient3@domain.com" -SmtpServer "smtp.office365.com" -Credential $mycreds -UseSsl "Server is DOWN!" -Port "587" -Body "This is an automatically generated message.<br>Please check on the status of your server, as it appears to be down currently.<br> You may need to reboot the service and/or server to get it back up and running.<br>Best regards<br><b>Your Server Support Bot</b>" -From $username -BodyAsHtml
            $emailsent = 'True'
        }
        else {
            write-host "Email has been sent to support!"
        }
    }

    #if you don't receive anything, email support
    elseif(!$siteup){
        Send-MailMessage -To "recipient1@domain.com" -Cc "recipient2@domain.com","recipient3@domain.com" -SmtpServer "smtp.office365.com" -Credential $mycreds -UseSsl "Server is DOWN!" -Port "587" -Body "This is an automatically generated message.<br>Please check on the status of your server, as it appears to be down currently.<br> You may need to reboot the service and/or server to get it back up and running.<br>Best regards<br><b>Your Server Support Bot</b>" -From $username -BodyAsHtml
        $emailsent = 'True'
    }
    #if status code is 200, don't do anything just say it's working
    else {
        Write-Host "Server is returning a 200 status, and expected text exists.  We should be good here!"
        $emailsent = 'False'
    }

    #sleep for a predetermined interval.  15 minutes/900 seconds is reasonable
    start-sleep -seconds 900
}
