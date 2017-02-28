# Make sure there is a directory to store secure creds in - create one if it doesn't exist
if(!(Test-Path -Path C:\temp )){
    New-Item -ItemType Directory -Force -Path C:\temp
}

# Receive creds from user and store as variable
#    Disabled below line because it would prevent the script from running automatically at startup
#    Left this as a comment, however, so that if someone wants to use it, it can easily be added back
#    $username = Read-Host -Prompt "Please enter the email address you want to send from:"
$username = "youraccount@domain.com"

# Create a file to store your email password
if(!(Test-Path -Path C:\temp\securestring.txt )){
    read-host -assecurestring "Please enter your password" | convertfrom-securestring | out-file C:\temp\securestring.txt
}
$password = cat C:\temp\securestring.txt | convertto-securestring
$mycreds = new-object -typename System.Management.Automation.PSCredential `
         -argumentlist $username, $password

# Creating variable to detect whether or not a support email has been generated.  
# This acts as a flag to ensure tickets don't get repeatedly generated while the incident is ongoing, and can be reset once connectivity is re-established
$emailsent = 'na'
# Infinite loop for calling connect function
while(1)
{
    # Get all of your time info to use later for tracking script functions
    $a = Get-Date
    $hour = $a.Hour
    $minute = $a.Minute
    # Send an email to an account you monitor, to ensure that the script is running every day.  
    if ($hour -eq '7' -And $Minute -gt 44) {
        Send-MailMessage -To "recipient1@domain.com" -Cc "recipient2@domain.com" -SmtpServer "smtp.office365.com" -Credential $mycreds -UseSsl "Serverbot is running :)" -Port "587" -Body "The script is still running" -From $username -BodyAsHtml
    }
    # Get the website and statuscode, then look at the content to ensure the word you want to see is in it ("Generous" is the one I used most recently)
    #    TUNE THIS IF YOUR SITE IS SLOWER THAN THAT - Default timeout is 60 seconds, or 1 minute, which should be good enough for most sites.  
    $webrequest = (Invoke-WebRequest -URI "https://monitoredserver.com" -UseBasicParsing -TimeoutSec 60)
    write-host $a
    $content = $webrequest.content
    $siteup = $content.tostring() -split "[`r`n]" | select-string -Pattern "generous"

    # If the script cannot download the page and find a word you want to see, email support or do nothing if flag is set
    #    Was previously using statuscode for this functionality, but realized that the site could be up but the service unavailable, like in a DoS situation, or a crashed process
    if (!$siteup) {
        if ($emailsent -ne 'True') {
            Send-MailMessage -To "recipient1@domain.com" -Cc "recipient2@domain.com","recipient3@domain.com" -SmtpServer "smtp.office365.com" -Credential $mycreds -UseSsl "Server is DOWN!" -Port "587" -Body "This is an automatically generated message.<br>Please check on the status of your server, as it appears to be down currently.<br> You may need to reboot the service and/or server to get it back up and running.<br>Best regards<br><b>Your Server Support Bot</b>" -From $username -BodyAsHtml
            $emailsent = 'True'
        }
        else {
            write-host "Email has been sent to support!"
        }
    }

    # If the script cannot download the page and find a word you want to see, email support or do nothing if flag is set
    #    Was previously using statuscode for this functionality, but realized that the site could be up but the service unavailable, like in a DoS situation, or a crashed process
    elseif (!$webrequest) {
        if ($emailsent -ne 'True') {
            Send-MailMessage -To "recipient1@domain.com" -Cc "recipient2@domain.com","recipient3@domain.com" -SmtpServer "smtp.office365.com" -Credential $mycreds -UseSsl "Server is DOWN!" -Port "587" -Body "This is an automatically generated message.<br>Please check on the status of your server, as it appears to be down currently.<br> You may need to reboot the service and/or server to get it back up and running.<br>Best regards<br><b>Your Server Support Bot</b>" -From $username -BodyAsHtml
            $emailsent = 'True'
        }
        else {
            write-host "Email has been sent to support!"
        }
    }

    # If you can see the content from $siteup, then you have to be getting a 200 status, and all is working.
    #    When this runs, reset $emailsent to False to ensure the next time the site is down, it will work properly
    else {
        Write-Host "Server is returning a 200 status, and expected text exists.  We should be good here!"
        $emailsent = 'False'
    }

    # Sleep for a predetermined interval.  15 minutes/900 seconds is reasonable in most cases
    start-sleep -seconds 900
}
