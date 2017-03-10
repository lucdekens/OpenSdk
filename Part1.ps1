Class rOpenSdk
{
    [String]$Name
    [String]$User
    [String]$SessionSecret
    [String]$Auth
    [String]$Uri
}

function Invoke-RestCall
{
  [CmdletBinding()]
  param (
    [String]$Method,
    [String]$Request,
    [PSObject]$Body
  )
	
  Process
  {
    Write-Verbose -Message "$($MyInvocation.MyCommand.Name)"
    Write-Verbose -Message "`t$($PSCmdlet.ParameterSetName)"
    Write-Verbose -Message "`tCalled from $($stack = Get-PSCallStack; $stack[1].Command) at $($stack[1].Location)"

    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add('Accept','application/json')
    $sRest = @{
      Uri         = $script:DefaultRestServer.Uri,$Request -join '/'
      Method      = $Method
      ContentType = 'application/json'
      Headers     = $local:headers
      ErrorAction = 'Stop'
    }
    if(!$script:DefaultRestServer.SessionSecret){
        $sRest.Headers.Add('Authorization',$script:DefaultRestServer.Auth)
        $sRest.Add('SessionVariable','rSession')
    }
    else{
        $sRest.Add('WebSession',$script:rSession)
    }
    if (Get-Process -Name fiddler -ErrorAction SilentlyContinue)
    {$sRest.Add('Proxy', 'http://127.0.0.1:8888')}

    # To handle nested properties the Depth parameter is used explicitely (default is 2)
    if ($Body.Count -ne 0)
    {
        $sRest.Add('Body', ($Body | ConvertTo-Json -Depth 32 -Compress))
    }

    Write-Debug -Message "`tUri             : $($sRest.Uri)"
    Write-Debug -Message "`tMethod          : $($sRest.Method)"
    Write-Debug -Message "`tContentType     : $($sRest.ContentType)"
    Write-Debug -Message "`tHeaders"
    $sRest.Headers.GetEnumerator() | ForEach-Object -Process {Write-Debug -Message "`t                : $($_.Name)`t$($_.Value)"}
    Write-Debug -Message "`tBody            : $($sRest.Body)"
		
    # The intermediate $result is used to avoid returning a PSMemberSet
    Try
    {
        $result = Invoke-RestMethod @sRest
        $script:DefaultRestServer.SessionSecret = $result.Value
        $script:rSession = $rSession
    }
    Catch
    {
      $excpt = $_.Exception

      Write-Debug -Message 'Exception'
      Write-Debug -Message "`tERROR-CODE = $($excpt.Response.Headers['ERROR-CODE'])"
      Write-Debug -Message "`tERROR-CODE = $($excpt.Response.Headers['ERROR-MESSAGE'])"
    }
    $result 
    Write-Debug -Message 'Leaving Invoke-hRavelloRest'
  }
}

function Get-rAuthHeader
{
  [CmdletBinding()]
  param (
    [String]$User,
    [String]$Password
  )
	
  Process
  {
    Write-Verbose -Message "$($MyInvocation.MyCommand.Name)"
    Write-Verbose -Message "`t$($PSCmdlet.ParameterSetName)"
    Write-Verbose -Message "`tCalled from $($stack = Get-PSCallStack; $stack[1].Command) at $($stack[1].Location)"
		
    $Encoded = [System.Text.Encoding]::UTF8.GetBytes(($User,$Password -Join ':'))
    $EncodedPassword = [System.Convert]::ToBase64String($Encoded)
    Write-Debug -Message "`tEncoded  : $($EncodedPassword)"
		
    "Basic $($EncodedPassword)"
  }
}

function Connect-rViServer{
    [CmdletBinding()]
    param(
        [String]$Server,
        [String]$User,
        [String]$Password
    )

    Write-Verbose -Message "$($MyInvocation.MyCommand.Name)"
    Write-Verbose -Message "`t$($PSCmdlet.ParameterSetName)"
    Write-Verbose -Message "`tCalled from $($stack = Get-PSCallStack; $stack[1].Command) at $($stack[1].Location)"
		
    $obj = [rOpenSdk]::New()
    $obj.Name = $Server
    $obj.User = $User
    $obj.Uri = "https://$($Server)/rest"
    $obj.Auth = Get-rAuthHeader -User $User -Password $Password

    $script:DefaultRestServer = $obj
    $sRestCall = @{
        Method = 'POST'
        Request = 'com/vmware/cis/session'
        Body = $null
    }
    Invoke-RestCall @sRestCall
}

function Get-rVMHost{
    param(
        [string[]]$Cluster,
        [string[]]$Datacenter,
        [string[]]$Folder,
        [string[]]$VMhost,
        [string[]]$Name,
        [string[]]$ConnectionState,
        [switch]$StandAlone = $false
    )

    Write-Verbose -Message "$($MyInvocation.MyCommand.Name)"
    Write-Verbose -Message "`t$($PSCmdlet.ParameterSetName)"
    Write-Verbose -Message "`tCalled from $($stack = Get-PSCallStack; $stack[1].Command) at $($stack[1].Location)"
		
    $sRestCall = @{
        Method = 'GET'
        Request = 'vcenter/host'
    }
    $body = @{}
    if($Cluster){
        $body.Add('clusters',$Cluster)
    }
    if($Datacenter){
        $body.Add('datacenters',$Datacenter)
    }
    if($Folder){
        $body.Add('folders',$Folder)
    }
    if($VMHost){
        $body.Add('hosts',$VMHost)
    }
    if($Name){
        $body.Add('names',$Name)
    }
    if($ConnectionState){
        $body.Add('connection_states',$ConnectionState)
    }
    if($StandAlone -ne $false){
        $body.Add('standalone',$StandAlone)
    }
    if($body){
        $sRestCall.Add('Body',$body)
    }
    Invoke-RestCall @sRestCall
}
