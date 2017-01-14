#make sure there is a directory to store secure creds in
if(!(Test-Path -Path C:\temp )){
    New-Item -ItemType Directory -Force -Path C:\temp
}
 
#receive creds from user and store as variable
$username = "you@youremail.com"
 
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
    $minut = $a.Minute
    if ($hour -eq '8' -And $Minute -gt 44) {
        Send-MailMessage -To "you@youremail.com" -Cc "sometech@somewhere.com" -SmtpServer "smtp.office365.com" -Credential $mycreds -UseSsl "ServerBot is running :)" -Port "587" -Body "The script is still running" -From $username -BodyAsHtml
    }
 
    $statuscode = (Invoke-WebRequest -URI "https:/path.to.server.com/morepath/something.htm" -UseBasicParsing -TimeoutSec 60).StatusCode
   
    #if status code is not 200, send an email to support or do nothing if email has been sent
    if ($statuscode -ne 200) {
        if ($emailsent -ne 'True') {
            Send-MailMessage -To "support@company.com" -Cc "someone@somewhere.org","anothercontact@somewhere.com" -SmtpServer "smtp.office365.com" -Credential $mycreds -UseSsl "The server is DOWN!" -Port "587" -Body "This is an automatically generated message.<br>Please check on the status of your server, as it appears to be down currently.<br> You may need to reboot the service and/or server to get it back up and running.<br>Best regards<br><b>Your Server Support Bot</b>" -From $username -BodyAsHtml
            $emailsent = 'True'
        }
        else {
            write-host "Email has been sent to support!"
        }
    }
 
    #if status code is 200, don't do anything just say it's working
    else {
        Write-Host "Server is returning a 200 status.  We should be good here!"
    }
 
    #sleep for a predetermined interval.  15 minutes/900 seconds is okay for our current application
    start-sleep -seconds 900
}
