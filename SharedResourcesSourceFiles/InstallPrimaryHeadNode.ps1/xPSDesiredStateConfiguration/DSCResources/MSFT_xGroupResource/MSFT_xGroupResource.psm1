<#
    Implementatation Notes

    Managing Disposable Objects
        The types PrincipalContext, Principal, and DirectoryEntry are used througout the code and
        all are disposable. However, in many cases, disposing the object immediately causes
        subsequent operations to fail or duplicate dispose calls to occur.

        To simplify management of these disposables, each public entry point defines a $disposables
        ArrayList variable and passes it to secondary functions that may need to create disposable
        objects. The public entry point is then required to dispose the contents of the list in a
        finally block.

    Managing PrincipalContext Instances
        To use the AccountManagement APIs to connect to the local machine or a domain, a
        PrincipalContext is needed.

        For the local groups and users, a PrincipalContext reflecting the current user can be
        created.

        For the default domain, the domain where the machine is joined, explicit credentials are
        needed since the default user context is SYSTEM which has no rights to the domain.

        Additional PrincipalContext instances may be needed when the machine is in a domain that is
        part of a multi-domain forest. For example, Microsoft uses a multi-domain forest that
        includes domains such as ntdev, redmond, wingroup and a group may have members that
        span multiple domains. Unless the enterprise implements the Global Catalog,
        something that Microsoft does not do, a unique PrincipalContext is needed to resolve
        accounts in each of the domains.

        To manage the use of PrincipalContext across domains, public entry points define a
        $principalContexts hashtable and pass it to support functions that need to resolve a group
        or group member. Consumers of a PrincipalContext call Get-PrincipalContext with a scope
        (domain name or machine name). Get-PrincipalContext returns an existing hashtable entry or
        creates a new entry.  Note that a PrincipalContext to a target domain requires connecting
        to the domain. The hashtable avoids subsequent connection calls. Also note that
        Get-PrincipalContext takes a Credential parameter for the case where a new PrincipalContext
        is needed. The implicit assumption is that the credential provided for the primary domain
        also has rights to resolve accounts in any of the other domains.

    Resolving Group Members
        The original implementation assumed that group members could be resolved using the machine
        PrincipalContext or the logged on user. In practice this is not reliable since the resource
        is typically run under the SYSTEM account and this account is not guaranteed to have rights
        to resolve domain accounts. Additionally, the APIs for enumerating group members do not
        provide a facility for passing additional credentials resulting in domain members failing
        to resolve.

        To address this, group members are enumerated by first converting the GroupPrincipal to a
        DirectoryEntry and enumerating its child members. The returned DirectoryEntry instances are
        then resolved to Principal objects using a PrincipalContext appropriate for the target
        domain.

        See Resolve-GroupMembersToPrincipals for more details.

    Handling Stale Group Members
        A group may have stale members if the machine was moved from one domain to a another
        foreign domain or when accounts are deleted (domain or local). At this point, members that
        were defined in the original domain or were deleted are now stale and cannot be resolved
        using Principal::FindByIdentity. The original implementation failed at this point
        preventing any operations against the group. The current implementation calls Write-Warning
        with the associated SID of the member that cannot be resolved then continues the operation.
#>

# A global variable that contains localized messages.
data LocalizedData
{
# culture="en-US"
ConvertFrom-StringData @'
GroupWithName = Group: {0}
RemoveOperation = Remove
AddOperation = Add
SetOperation = Set
GroupCreated = Group {0} created successfully.
GroupUpdated = Group {0} properties updated successfully.
GroupRemoved = Group {0} removed successfully.
NoConfigurationRequired = Group {0} exists on this node with the desired properties. No action required.
NoConfigurationRequiredGroupDoesNotExist = Group {0} does not exist on this node. No action required.
CouldNotFindPrincipal = Could not find a principal with the provided name [{0}]
MembersAndIncludeExcludeConflict = The {0} and {1} parameters conflict. The {0} parameter should not be used in any combination with the {1} parameter.
MembersIsNull = The Members parameter value is null. The {0} parameter must be provided if neither {1} nor {2} is provided.
MembersIsEmpty = The Members parameter is empty.  At least one group member must be provided.
MemberNotValid = The group member does not exist or cannot be resolved: {0}.
IncludeAndExcludeConflict = The principal {0} is included in both {1} and {2} parameter values. The same principal must not be included in both {1} and {2} parameter values.
IncludeAndExcludeAreEmpty = The MembersToInclude and MembersToExclude are either both null or empty.  At least one member must be specified in one of these parameters"
InvalidGroupName = The name {0} cannot be used. Names may not consist entirely of periods and/or spaces, or contain these characters: {1}
GroupExists = A group with the name {0} exists.
GroupDoesNotExist = A group with the name {0} does not exist.
PropertyMismatch = The value of the {0} property is expected to be {1} but it is {2}.
MembersNumberMismatch = Property {0}. The number of provided unique group members {1} is different from the number of actual group members {2}.
MembersMemberMismatch = At least one member {0} of the provided {1} parameter does not have a match in the existing group {2}.
MemberToExcludeMatch = At least one member {0} of the provided {1} parameter has a match in the existing group {2}.
ResolvingLocalAccount = Resolving {0} as a local account.
ResolvingDomainAccount = Resolving {0} in the {1} domain.
ResolvingDomainAccountWithTrust = Resolving {0} with domain trust.
DomainCredentialsRequired = Credentials are required to resolve the domain account {0}.
UnableToResolveAccount = Unable to resolve account '{0}'. Failed with message: {1} (error code={2})
'@
}

# Commented-out until more languages are supported
# Import-LocalizedData -BindingVariable 'LocalizedData' -FileName 'MSFT_xGroupResource.strings.psd1'

Import-Module -Name "$PSScriptRoot\..\CommonResourceHelper.psm1"

if (-not (Test-IsNanoServer))
{
    Add-Type -AssemblyName 'System.DirectoryServices.AccountManagement'
}

function Get-TargetResource
{
    [OutputType([Hashtable])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $GroupName,

        [PSCredential]
        $Credential
    )

    if (Test-IsNanoServer)
    {
        return Get-TargetResourceOnNanoServer @PSBoundParameters
    }
    else
    {
        return Get-TargetResourceOnFullSKU @PSBoundParameters
    }
}

function Set-TargetResource
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $GroupName,

        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present',

        [String]
        $Description,

        [String[]]
        $Members,

        [String[]]
        $MembersToInclude,

        [String[]]
        $MembersToExclude,

        [ValidateNotNullOrEmpty()]
        [PSCredential]
        $Credential
    )

    if (Test-IsNanoServer)
    {
        Set-TargetResourceOnNanoServer @PSBoundParameters
    }
    else
    {
        Set-TargetResourceOnFullSKU @PSBoundParameters
    }
}

function Test-TargetResource
{
    [OutputType([Boolean])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $GroupName,

        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present',

        [String]
        $Description,

        [String[]]
        $Members,

        [String[]]
        $MembersToInclude,

        [String[]]
        $MembersToExclude,

        [ValidateNotNullOrEmpty()]
        [PSCredential]
        $Credential
    )

    if (Test-IsNanoServer)
    {
        return Test-TargetResourceOnNanoServer @PSBoundParameters
    }
    else
    {
        return Test-TargetResourceOnFullSKU @PSBoundParameters
    }
}

<#
    .SYNOPSIS
        The Get-TargetResource cmdlet for a full server.

    .PARAMETER GroupName
        The name of the xGroup resource to retrieve.

    .PARAMETER Credential
        The credential to use to retrieve the xGroup resource.
#>
function Get-TargetResourceOnFullSKU
{
    [OutputType([Hashtable])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $GroupName,

        [PSCredential]
        $Credential
    )

    Set-StrictMode -Version 'Latest'

    Assert-GroupNameValid -GroupName $GroupName

    $principalContexts = @{}
    $disposables = New-Object -TypeName 'System.Collections.ArrayList'

    try
    {
        $group = Get-Group -GroupName $GroupName -PrincipalContexts $principalContexts -Disposables $disposables

        if ($null -ne $group)
        {
            $disposables.Add($group) | Out-Null

            # The group is found. Enumerate all group members.
            $members = Get-MembersOnFullSKU -Group $group -PrincipalContexts $principalContexts -Disposables $disposables -Credential $Credential

            $returnValue = @{
                GroupName = $group.Name
                Ensure = 'Present'
                Description = $group.Description
                Members = $members
            }

            return $returnValue
        }

        # The group is not found.
        return @{
            GroupName = $GroupName
            Ensure = 'Absent'
        }
    }
    finally
    {
        Remove-Disposables -Disposables $disposables
    }
}

<#
    .SYNOPSIS
        The Set-TargetResource cmdlet on a full server.

    .PARAMETER GroupName
        The name of the group for which you want to ensure a specific state.

    .PARAMETER Ensure
        Indicates if the group exists. Set this property to 'Absent' to ensure that the group does
        not exist. Setting it to 'Present' (the default value) ensures that the group exists.

    .PARAMETER Description
        The description of the group.

    .PARAMETER Members
        Use this property to replace the current group membership with the specified members. The
        value of this property is an array of strings of the form Domain\UserName. If you set this
        property in a configuration, do not use either the MembersToExclude or MembersToInclude
        property. Doing so will generate an error.

    .PARAMETER MembersToInclude
        Use this property to add members to the existing membership of the group. The value of this
        property is an array of strings of the form Domain\UserName. If you set this property in a
        configuration, do not use the Members property. Doing so will generate an error.

    .PARAMETER MembersToExclude
        Use this property to remove members from the existing membership of the group. The value of
        this property is an array of strings of the form Domain\UserName. If you set this property
        in a configuration, do not use the Members property. Doing so will generate an error.

    .PARAMETER Credential
        The credentials required to access remote resources. Note: This account must have the
        appropriate Active Directory permissions to add all non-local accounts to the group.
        Otherwise, an error will occur.
#>
function Set-TargetResourceOnFullSKU
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $GroupName,

        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present',

        [String]
        $Description,

        [ValidateNotNull()]
        [String[]]
        $Members,

        [String[]]
        $MembersToInclude,

        [String[]]
        $MembersToExclude,

        [ValidateNotNullOrEmpty()]
        [PSCredential]
        $Credential
    )

    Set-StrictMode -Version 'Latest'

    Assert-GroupNameValid -GroupName $GroupName

    $principalContexts = @{}
    $disposables = New-Object -TypeName 'System.Collections.ArrayList'

    try
    {
        # Try to find a group by its name.
        $group = Get-Group -GroupName $GroupName -PrincipalContexts $principalContexts -Disposables $disposables
        $groupOriginallyExists = $null -ne $group

        if ($Ensure -eq 'Present')
        {
            $actualMembersAsPrincipals = $null

            if ($groupOriginallyExists)
            {
                $disposables.Add($group) | Out-Null
                $whatIfShouldProcess = $pscmdlet.ShouldProcess(($LocalizedData.GroupWithName -f $GroupName), $LocalizedData.SetOperation)

                $actualMembersAsPrincipals = @( Get-MembersAsPrincipals `
                    -Group $group `
                    -PrincipalContexts $principalContexts `
                    -Disposables $disposables `
                    -Credential $Credential )
            }
            else
            {
                $whatIfShouldProcess = $pscmdlet.ShouldProcess(($LocalizedData.GroupWithName -f $GroupName), $LocalizedData.AddOperation)
            }

            if ($whatIfShouldProcess)
            {
                $saveChanges = $false

                if (-not $groupOriginallyExists)
                {
                    $localPrincipalContext = Get-PrincipalContext -PrincipalContexts $principalContexts -Disposables $disposables -Scope $env:computerName

                    $group = New-Object -TypeName 'System.DirectoryServices.AccountManagement.GroupPrincipal' -ArgumentList @( $localPrincipalContext )
                    $disposables.Add($group) | Out-Null

                    $group.Name = $GroupName
                    $saveChanges = $true
                }

                # Set group properties.

                if ($PSBoundParameters.ContainsKey('Description') -and $Description -ne $group.Description)
                {
                    $group.Description = $Description
                    $saveChanges = $true
                }

                <#
                    Group members can be updated in two ways:
                    1. Supplying the Members parameter - this causes the membership to be replaced with the members defined in Members.
                        NOTE: If Members is empty, the group membership is cleared.
                    2. Providing MembersToInclude and/or MembersToExclude - this adds/removes members from the list.
                        If Members is mutually exclusive with MembersToInclude and MembersToExclude
                        If Members is not defined then MembersToInclude or MembersToExclude must contain at least one entry.
                #>
                if ($PSBoundParameters.ContainsKey('Members'))
                {
                    if ($PSBoundParameters.ContainsKey('MembersToInclude'))
                    {
                        New-InvalidArgumentException -ArgumentName 'MembersToInclude' -Message ($LocalizedData.MembersAndIncludeExcludeConflict -f 'Members', 'MembersToInclude')
                    }

                    if ($PSBoundParameters.ContainsKey('MembersToExclude'))
                    {
                        New-InvalidArgumentException -ArgumentName 'MembersToExclude' -Message ($LocalizedData.MembersAndIncludeExcludeConflict -f 'Members', 'MembersToExclude')
                    }

                    if ($Members.Count -eq 0 -and $null -ne $group.Members -and $group.Members.Count -ne 0)
                    {
                        $group.Members.Clear()
                        $saveChanges = $true
                    }
                    elseif ($Members.Count -ne 0)
                    {
                        # Remove duplicate names as strings.
                        $Members = Remove-DuplicateMembers -Members $Members

                        # Resolve the names to actual principal objects.
                        $membersAsPrincipals = ConvertTo-Principals `
                            -MemberNames $Members `
                            -PrincipalContexts $principalContexts `
                            -Disposables $disposables `
                            -Credential $Credential

                        if ($membersAsPrincipals.Count -gt 0)
                        {
                            if ($null -ne $actualMembersAsPrincipals -and $actualMembersAsPrincipals.Count -gt 0)
                            {
                                $membersToAdd = @()
                                $membersToRemove = @()

                                foreach ($membersAsPrincipal in $membersAsPrincipals)
                                {
                                    if ($actualMembersAsPrincipals -notcontains $membersAsPrincipal)
                                    {
                                        $membersToAdd += $membersAsPrincipal
                                    }
                                }

                                foreach ($actualMembersAsPrincipal in $actualMembersAsPrincipals)
                                {
                                    if ($membersAsPrincipals -notcontains $actualMembersAsPrincipal)
                                    {
                                        $membersToRemove += $actualMembersAsPrincipal
                                    }
                                }

                                # Set the members of the group
                                if (Add-GroupMembers -Group $group -MembersAsPrincipals $membersToAdd)
                                {
                                    $saveChanges = $true
                                }

                                if (Remove-GroupMembers -Group $group -MembersAsPrincipals $membersToRemove)
                                {
                                    $saveChanges = $true
                                }
                            }
                            else
                            {
                                # Set the members of the group
                                if (Add-GroupMembers -Group $group -MembersAsPrincipals $membersAsPrincipals)
                                {
                                    $saveChanges = $true
                                }
                            }
                        }
                        else
                        {
                            # ISSUE: Is an empty $Members parameter valid?
                            New-InvalidArgumentException -ArgumentName 'Members' -Message ($LocalizedData.MembersIsEmpty)
                        }
                    }
                }
                else
                {

                    $membersToIncludeAsPrincipals = $null
                    if ($PSBoundParameters.ContainsKey('MembersToInclude'))
                    {
                        $MembersToInclude = Remove-DuplicateMembers -Members $MembersToInclude

                        # Resolve the names to actual principal objects.
                        $membersToIncludeAsPrincipals = @( ConvertTo-Principals `
                            -MemberNames $MembersToInclude `
                            -PrincipalContexts $principalContexts `
                            -Disposables $disposables `
                            -Credential $Credential
                        )
                    }

                    $membersToExcludeAsPrincipals = $null
                    if ($PSBoundParameters.ContainsKey('MembersToExclude'))
                    {
                        $MembersToExclude = Remove-DuplicateMembers -Members $MembersToExclude

                        # Resolve the names to actual principal objects.
                        $membersToExcludeAsPrincipals = @( ConvertTo-Principals `
                            -MemberNames $MembersToExclude `
                            -PrincipalContexts $principalContexts `
                            -Disposables $disposables `
                            -Credential $Credential
                        )
                    }

                    if ($null -ne $membersToIncludeAsPrincipals -and $null -ne $membersToExcludeAsPrincipals)
                    {
                        # Both MembersToInclude and MembersToExclude were provided. Check if they have any common principals.
                        foreach ($includedPrincipal in $membersToIncludeAsPrincipals)
                        {
                            foreach ($excludedPrincipal in $membersToExcludeAsPrincipals)
                            {
                                if ($includedPrincipal -eq $excludedPrincipal)
                                {
                                    New-InvalidArgumentException -ArgumentName 'MembersToInclude and MembersToExclude' -Message ($LocalizedData.IncludeAndExcludeConflict -f $includedPrincipal.SamAccountName,'MembersToInclude', 'MembersToExclude')
                                }
                            }
                        }

                        if ($membersToIncludeAsPrincipals.Count -eq 0 -and $membersToExcludeAsPrincipals.Count -eq 0)
                        {
                            New-InvalidArgumentException -ArgumentName 'MembersToInclude and MembersToExclude' -Message ($LocalizedData.IncludeAndExcludeAreEmpty)
                        }
                    }

                    if ($null -ne $membersToExcludeAsPrincipals -and $membersToExcludeAsPrincipals.Count -gt 0)
                    {
                        if (Remove-GroupMembers -Group $group -MembersAsPrincipals $membersToExcludeAsPrincipals)
                        {
                            $saveChanges = $true
                        }
                    }

                    if ($null -ne $membersToIncludeAsPrincipals -and $membersToIncludeAsPrincipals.Count -gt 0)
                    {
                        if (Add-GroupMembers -Group $group -MembersAsPrincipals $membersToIncludeAsPrincipals)
                        {
                            $saveChanges = $true
                        }
                    }
                }

                if ($saveChanges)
                {
                    $group.Save()

                    # Send an operation success verbose message.
                    if ($groupOriginallyExists)
                    {
                        Write-Verbose -Message ($LocalizedData.GroupUpdated -f $GroupName)
                    }
                    else
                    {
                        Write-Verbose -Message ($LocalizedData.GroupCreated -f $GroupName)
                    }
                }
                else
                {
                    Write-Verbose -Message ($LocalizedData.NoConfigurationRequired -f $GroupName)
                }
            }
        }
        else
        {
            if ($groupOriginallyExists)
            {
                if ($PSCmdlet.ShouldProcess(($LocalizedData.GroupWithName -f $GroupName), $LocalizedData.RemoveOperation))
                {
                    # Don't add to $disposables since Delete also disposes.
                    $group.Delete()
                    Write-Verbose -Message ($LocalizedData.GroupRemoved -f $GroupName)
                }
                else
                {
                    $disposables.Add($group) | Out-Null
                }
            }
            else
            {
                Write-Verbose -Message ($LocalizedData.NoConfigurationRequiredGroupDoesNotExist -f $GroupName)
            }
        }
    }
    finally
    {
        Remove-Disposables -Disposables $disposables
    }
}

<#
    .SYNOPSIS
        The Test-TargetResource cmdlet on a full server
        Tests if the resource is in the given state.

    .PARAMETER GroupName
        The name of the group for which you want to ensure a specific state.

    .PARAMETER Ensure
        Indicates if the group exists. Set this property to 'Absent' to ensure that the group does
        not exist. Setting it to 'Present' (the default value) ensures that the group exists.

    .PARAMETER Description
        The description of the group.

    .PARAMETER Members
        Use this property to replace the current group membership with the specified members. The
        value of this property is an array of strings of the form Domain\UserName. If you set this
        property in a configuration, do not use either the MembersToExclude or MembersToInclude
        property. Doing so will generate an error.

    .PARAMETER MembersToInclude
        Use this property to add members to the existing membership of the group. The value of this
        property is an array of strings of the form Domain\UserName. If you set this property in a
        configuration, do not use the Members property. Doing so will generate an error.

    .PARAMETER MembersToExclude
        Use this property to remove members from the existing membership of the group. The value of
        this property is an array of strings of the form Domain\UserName. If you set this property
        in a configuration, do not use the Members property. Doing so will generate an error.

    .PARAMETER Credential
        The credentials required to access remote resources. Note: This account must have the
        appropriate Active Directory permissions to add all non-local accounts to the group.
        Otherwise, an error will occur.
#>
function Test-TargetResourceOnFullSKU
{
    [OutputType([Boolean])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $GroupName,

        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present',

        [String]
        $Description,

        [ValidateNotNull()]
        [String[]]
        $Members,

        [String[]]
        $MembersToInclude,

        [String[]]
        $MembersToExclude,

        [ValidateNotNullOrEmpty()]
        [PSCredential]
        $Credential
    )

    Set-StrictMode -Version 'Latest'

    Assert-GroupNameValid -GroupName $GroupName

    $principalContexts = @{}
    $disposables = New-Object -TypeName 'System.Collections.ArrayList'

    try
    {
        $group = Get-Group -GroupName $GroupName -PrincipalContexts $principalContexts -Disposables  $disposables

        if ($null -eq $group)
        {
            Write-Verbose -Message ($LocalizedData.GroupDoesNotExist -f $GroupName)
            return ($Ensure -eq 'Absent')
        }

        if ($null -ne $group.Members)
        {
            $actualGroupMembers = @($group.Members)
        }
        else
        {
            $actualGroupMembers = $null
        }

        $disposables.Add($group) | Out-Null
        Write-Verbose -Message ($LocalizedData.GroupExists -f $GroupName)

        # Validate separate properties.
        if ($Ensure -eq 'Absent')
        {
            Write-Verbose -Message ($LocalizedData.PropertyMismatch -f 'Ensure', 'Absent', 'Present')
            return $false
        }

        if ($PSBoundParameters.ContainsKey('GroupName') -and $GroupName -ne $group.SamAccountName -and $GroupName -ne $group.Sid.Value)
        {
            return $false
        }

        if ($PSBoundParameters.ContainsKey('Description') -and $Description -ne $group.Description)
        {
            Write-Verbose -Message ($LocalizedData.PropertyMismatch -f 'Description', $Description, $group.Description)
            return $false
        }

        if ($PSBoundParameters.ContainsKey('Members'))
        {
            if ($PSBoundParameters.ContainsKey('MembersToInclude'))
            {
                New-InvalidArgumentException -ArgumentName 'MembersToInclude' -Message ($LocalizedData.MembersAndIncludeExcludeConflict -f 'Members', 'MembersToInclude')
            }

            if ($PSBoundParameters.ContainsKey('MembersToExclude'))
            {
                New-InvalidArgumentException -ArgumentName 'MembersToExclude' -Message ($LocalizedData.MembersAndIncludeExcludeConflict -f 'Members', 'MembersToExclude')
            }

            if ($Members.Count -eq 0)
            {
                return ($null -eq $actualGroupMembers -or $actualGroupMembers.Count -eq 0)
            }
            else
            {
                # Remove duplicate names as strings.
                $Members = @( Remove-DuplicateMembers -Members $Members )

                # Resolve the names to actual principal objects.
                $expectedMembersAsPrincipals = @( ConvertTo-Principals `
                    -MemberNames $Members `
                    -PrincipalContexts $principalContexts `
                    -Disposables $disposables `
                    -Credential $Credential )

                if ($expectedMembersAsPrincipals.Count -ne $actualGroupMembers.Count)
                {
                    Write-Verbose -Message ($LocalizedData.MembersNumberMismatch -f 'Members', $expectedMembersAsPrincipals.Count, $actualGroupMembers.Count)
                    return $false
                }

                $actualMembersAsPrincipals = @( Get-MembersAsPrincipals `
                    -Group $group `
                    -PrincipalContexts $principalContexts `
                    -Disposables $disposables `
                    -Credential $Credential )

                # Compare the two member lists.
                foreach ($expectedMemberAsPrincipal in $expectedMembersAsPrincipals)
                {
                    if ($actualMembersAsPrincipals -notcontains $expectedMemberAsPrincipal)
                    {
                        Write-Verbose -Message ($LocalizedData.MembersMemberMismatch -f $expectedMember.SamAccountName, 'Members', $group.SamAccountName)
                        return $false
                    }
                }
            }
        }
        elseif ($PSBoundParameters.ContainsKey('MembersToInclude') -or $PSBoundParameters.ContainsKey('MembersToExclude'))
        {
            $actualMembersAsPrincipals = @( Get-MembersAsPrincipals `
                -Group $group `
                -PrincipalContexts $principalContexts `
                -Disposables $disposables `
                -Credential $Credential )

            if ($PSBoundParameters.ContainsKey('MembersToInclude'))
            {
                $MembersToInclude = @( Remove-DuplicateMembers -Members $MembersToInclude )

                # Resolve the names to actual principal objects.
                $expectedMembersAsPrincipals = ConvertTo-Principals `
                    -MemberNames $MembersToInclude `
                    -PrincipalContexts $principalContexts `
                    -Disposables $disposables `
                    -Credential $Credential

                # Compare two members lists.
                foreach ($expectedMemberAsPrincipal in $expectedMembersAsPrincipals)
                {
                    if ($actualMembersAsPrincipals -notcontains $expectedMemberAsPrincipal)
                    {
                        Write-Verbose -Message ($LocalizedData.MembersMemberMismatch -f $expectedMemberAsPrincipal.SamAccountName, 'MembersToInclude', $group.SamAccountName)
                        return $false
                    }
                }
            }

            if ($PSBoundParameters.ContainsKey('MembersToExclude'))
            {
                $MembersToExclude = @( Remove-DuplicateMembers -Members $MembersToExclude)

                # Resolve the names to actual principal objects.
                $notExpectedMembersAsPrincipals = ConvertTo-Principals `
                    -MemberNames $MembersToExclude `
                    -PrincipalContexts $principalContexts `
                    -Disposables $disposables `
                    -Credential $Credential

                foreach($notExpectedMemberAsPrincipal in $notExpectedMembersAsPrincipals)
                {
                    if ($actualMembersAsPrincipals -contains $notExpectedMemberAsPrincipal)
                    {
                        Write-Verbose -Message ($LocalizedData.MemberToExcludeMatch -f $notExpectedMemberAsPrincipal.SamAccountName, 'MembersToExclude', $group.SamAccountName)
                        return $false
                    }
                }
            }
        }
    }
    finally
    {
        Remove-Disposables $disposables
    }

    return $true
}

<#
    .SYNOPSIS
        The Get-TargetResource cmdlet for a Nano server.

    .PARAMETER GroupName
        The name of the xGroup resource to retrieve.

    .PARAMETER Credential
        The credential to use to retrieve the xGroup resource.
#>
function Get-TargetResourceOnNanoServer
{
    [OutputType([Hashtable])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $GroupName,

        [PSCredential]
        $Credential
    )

    Set-StrictMode -Version 'Latest'

    Assert-GroupNameValid -GroupName $GroupName

    try
    {
        $group = Get-LocalGroup -Name $GroupName -ErrorAction Stop
    }
    catch [System.Exception]
    {
        if ($_.CategoryInfo.Reason -eq 'GroupNotFoundException')
        {
            # The group is not found.
            return @{
                GroupName = $GroupName
                Ensure = 'Absent'
            }
        }

        New-InvalidOperationException -ErrorRecord $_
    }

    # The group is found. Enumerate all group members.
    $members = Get-MembersOnNanoServer -Group $group

    return @{
        GroupName = $group.Name
        Ensure = 'Present'
        Description = $group.Description
        Members = $members
    }
}

<#
    .SYNOPSIS
        The Set-TargetResource cmdlet on a Nano server.

    .PARAMETER GroupName
        The name of the group for which you want to ensure a specific state.

    .PARAMETER Ensure
        Indicates if the group exists. Set this property to 'Absent' to ensure that the group does
        not exist. Setting it to 'Present' (the default value) ensures that the group exists.

    .PARAMETER Description
        The description of the group.

    .PARAMETER Members
        Use this property to replace the current group membership with the specified members. The
        value of this property is an array of strings of the form Domain\UserName. If you set this
        property in a configuration, do not use either the MembersToExclude or MembersToInclude
        property. Doing so will generate an error.

    .PARAMETER MembersToInclude
        Use this property to add members to the existing membership of the group. The value of this
        property is an array of strings of the form Domain\UserName. If you set this property in a
        configuration, do not use the Members property. Doing so will generate an error.

    .PARAMETER MembersToExclude
        Use this property to remove members from the existing membership of the group. The value of
        this property is an array of strings of the form Domain\UserName. If you set this property
        in a configuration, do not use the Members property. Doing so will generate an error.

    .PARAMETER Credential
        The credentials required to access remote resources. Note: This account must have the
        appropriate Active Directory permissions to add all non-local accounts to the group.
        Otherwise, an error will occur.
#>
function Set-TargetResourceOnNanoServer
{
    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $GroupName,

        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present',

        [String]
        $Description,

        [ValidateNotNull()]
        [String[]]
        $Members,

        [String[]]
        $MembersToInclude,

        [String[]]
        $MembersToExclude,

        [ValidateNotNullOrEmpty()]
        [PSCredential]
        $Credential
    )

    Set-StrictMode -Version 'Latest'

    Assert-GroupNameValid -GroupName $GroupName

    $groupOriginallyExists = $false

    try
    {
        $group = Get-LocalGroup -Name $GroupName -ErrorAction Stop
        $groupOriginallyExists = $true
    }
    catch [System.Exception]
    {
        if ($_.CategoryInfo.Reason -eq 'GroupNotFoundException')
        {
            # A group with the provided name does not exist.
            Write-Verbose -Message ($LocalizedData.GroupDoesNotExist -f $GroupName)
        }
        else
        {
            New-InvalidOperationException -ErrorRecord $_
        }
    }

    if ($Ensure -eq 'Present')
    {
        if (-not $groupOriginallyExists)
        {
            New-LocalGroup -Name $GroupName
            Write-Verbose -Message ($LocalizedData.GroupCreated -f $GroupName)
        }

        # Set the group properties.

        if ($PSBoundParameters.ContainsKey('Description') -and ((-not $groupExists) -or ($Description -ne $group.Description)))
        {
            Set-LocalGroup -Name $GroupName -Description $Description
        }

        <#
            Group members can be updated in two ways:
            1. Supplying the Members parameter - this causes the membership to be replaced with the members defined in Members.
                NOTE: If Members is empty, the group membership is cleared.
            2. Providing MembersToInclude and/or MembersToExclude - this adds/removes members from the list.
                If Members is mutually exclusive with MembersToInclude and MembersToExclude
                If Members is not defined then MembersToInclude or MembersToExclude must contain at least one entry.
        #>

        if ($PSBoundParameters.ContainsKey('Members'))
        {
            if ($PSBoundParameters.ContainsKey('MembersToInclude'))
            {
                New-InvalidArgumentException -ArgumentName 'MembersToInclude' -Message ($LocalizedData.MembersAndIncludeExcludeConflict -f 'Members', 'MembersToInclude')
            }

            if ($PSBoundParameters.ContainsKey('MembersToExclude'))
            {
                New-InvalidArgumentException -ArgumentName 'MembersToExclude' -Message ($LocalizedData.MembersAndIncludeExcludeConflict -f 'Members', 'MembersToExclude')
            }

            # Remove duplicate names as strings.
            $Members = @( Remove-DuplicateMembers -Members $Members )

            if ($Members.Count -gt 0)
            {
                # Get current members
                $groupMembers = Get-MembersOnNanoServer -Group $group

                # Remove the current members of the group
                Remove-LocalGroupMember -Group $GroupName -Member $groupMembers

                # Add the list of expected members to the group
                Add-LocalGroupMember -Group $GroupName -Member $Members
            }
            else
            {
                New-InvalidArgumentException -ArgumentName 'Members' -Message ($LocalizedData.MembersIsEmpty)
            }
        }
        else
        {
            if ($PSBoundParameters.ContainsKey('MembersToInclude'))
            {
                $MembersToInclude = @( Remove-DuplicateMembers -Members $MembersToInclude )
            }

            if ($PSBoundParameters.ContainsKey('MembersToExclude'))
            {
                $MembersToExclude = @( Remove-DuplicateMembers -Members $MembersToExclude )
            }

            if ($PSBoundParameters.ContainsKey('MembersToInclude') -and $PSBoundParameters.ContainsKey('MembersToExclude'))
            {
                # Both MembersToInclude and MembersToExlude were provided. Check if they have common principals.
                foreach ($includedMember in $MembersToInclude)
                {
                    foreach($excludedMember in $MembersToExclude)
                    {
                        if ($includedMember -eq $excludedMember)
                        {
                            New-InvalidArgumentException -ArgumentName 'MembersToInclude and MembersToExclude' -Message ($LocalizedData.IncludeAndExcludeConflict -f $includedMember, 'MembersToInclude', 'MembersToExclude')
                        }
                    }
                }

                if ($MembersToInclude.Count -eq 0 -and $MembersToExclude.Count -eq 0)
                {
                    New-InvalidArgumentException -ArgumentName 'MembersToInclude and MembersToExclude' -Message ($LocalizedData.IncludeAndExcludeAreEmpty)
                }
            }

            if ($PSBoundParameters.ContainsKey('MembersToInclude'))
            {
                foreach ($includedMember in $MembersToInclude)
                {
                    try
                    {
                        Add-LocalGroupMember -Group $GroupName -Member $includedMember -ErrorAction Stop
                    }
                    catch [System.Exception]
                    {
                        if ($_.CategoryInfo.Reason -ne 'MemberExistsException')
                        {
                            throw $_.Exception
                        }
                    }
                }
            }

            if ($PSBoundParameters.ContainsKey('MembersToExclude'))
            {
                foreach($excludedMember in $MembersToExclude)
                {
                    try
                    {
                        Remove-LocalGroupMember -Group $GroupName -Member $excludedMember -ErrorAction Stop
                    }
                    catch [System.Exception]
                    {
                        if ($_.CategoryInfo.Reason -ne 'MemberNotFoundException')
                        {
                            New-InvalidOperationException -ErrorRecord $_
                        }
                    }
                }
            }
        }
    }
    else
    {
        # Ensure is set to "Absent".
        if ($groupOrginallyExists)
        {
            # The group exists. Remove the group by the provided name.
            Remove-LocalGroup -Name $GroupName
            Write-Verbose -Message ($LocalizedData.GroupRemoved -f $GroupName)
        }
        else
        {
            Write-Verbose -Message ($LocalizedData.NoConfigurationRequiredGroupDoesNotExist -f $GroupName)
        }
    }
}

<#
    .SYNOPSIS
        The Test-TargetResource cmdlet on a Nano server
        Tests if the resource is in the given state.

    .PARAMETER GroupName
        The name of the group for which you want to ensure a specific state.

    .PARAMETER Ensure
        Indicates if the group exists. Set this property to 'Absent' to ensure that the group does
        not exist. Setting it to 'Present' (the default value) ensures that the group exists.

    .PARAMETER Description
        The description of the group.

    .PARAMETER Members
        Use this property to replace the current group membership with the specified members. The
        value of this property is an array of strings of the form Domain\UserName. If you set this
        property in a configuration, do not use either the MembersToExclude or MembersToInclude
        property. Doing so will generate an error.

    .PARAMETER MembersToInclude
        Use this property to add members to the existing membership of the group. The value of this
        property is an array of strings of the form Domain\UserName. If you set this property in a
        configuration, do not use the Members property. Doing so will generate an error.

    .PARAMETER MembersToExclude
        Use this property to remove members from the existing membership of the group. The value of
        this property is an array of strings of the form Domain\UserName. If you set this property
        in a configuration, do not use the Members property. Doing so will generate an error.

    .PARAMETER Credential
        The credentials required to access remote resources. Note: This account must have the
        appropriate Active Directory permissions to add all non-local accounts to the group.
        Otherwise, an error will occur.
#>
function Test-TargetResourceOnNanoServer
{
    [OutputType([Boolean])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $GroupName,

        [ValidateSet('Present', 'Absent')]
        [String]
        $Ensure = 'Present',

        [String]
        $Description,

        [ValidateNotNull()]
        [String[]]
        $Members,

        [String[]]
        $MembersToInclude,

        [String[]]
        $MembersToExclude,

        [ValidateNotNullOrEmpty()]
        [PSCredential]
        $Credential
    )

    Set-StrictMode -Version 'Latest'

    Assert-GroupNameValid -GroupName $GroupName

    try
    {
        $group = Get-LocalGroup -Name $GroupName -ErrorAction Stop
    }
    catch [System.Exception]
    {
        if ($_.CategoryInfo.Reason -eq 'GroupNotFoundException')
        {
            # A group with the provided name does not exist.
            Write-Verbose -Message ($LocalizedData.GroupDoesNotExist -f $GroupName)

            return ($Ensure -eq 'Absent')
        }

        New-InvalidOperationException -ErrorRecord $_
    }

    # A group with the provided name exists.
    Write-Verbose -Message ($LocalizedData.GroupExists -f $GroupName)

    # Validate separate properties.
    if ($Ensure -eq 'Absent')
    {
        Write-Verbose -Message ($LocalizedData.PropertyMismatch -f 'Ensure', 'Absent', 'Present')
        return $false
    }

    if ($PSBoundParameters.ContainsKey('Description') -and $Description -ne $group.Description)
    {
        Write-Verbose -Message ($LocalizedData.PropertyMismatch -f 'Description', $Description, $group.Description)
        return $false
    }

    if ($PSBoundParameters.ContainsKey('Members'))
    {
        if ($PSBoundParameters.ContainsKey('MembersToInclude'))
        {
            New-InvalidArgumentException -ArgumentName 'MembersToInclude' -Message ($LocalizedData.MembersAndIncludeExcludeConflict -f 'Members', 'MembersToInclude')
        }

        if ($PSBoundParameters.ContainsKey('MembersToExclude'))
        {
            New-InvalidArgumentException -ArgumentName 'MembersToExclude' -Message ($LocalizedData.MembersAndIncludeExcludeConflict -f 'Members', 'MembersToExclude')
        }

        # Remove duplicate names as strings.
        $expectedMembers = @( Remove-DuplicateMembers -Members $Members )

        # Get current members
        $groupMembers = Get-MembersOnNanoServer -Group $group

        if ($expectedMembers.Count -ne $groupMembers.Count)
        {
            Write-Verbose -Message ($LocalizedData.MembersNumberMismatch -f 'Members', $expectedMembers.Count, $groupMembers.Count)
            return $false
        }

        # Compare two members lists.
        foreach ($expectedMember in $expectedMembers)
        {
            if ($groupMembers -notcontains $expectedMember)
            {
                Write-Verbose -Message ($LocalizedData.MembersMemberMismatch -f $expectedMember, 'Members', $group.Name)
                return $false
            }
        }
    }
    else
    {
        # Get current members
        $groupMembers = Get-MembersOnNanoServer -Group $group

        if ($PSBoundParameters.ContainsKey('MembersToInclude'))
        {
            $MembersToInclude = @( Remove-DuplicateMembers -Members $MembersToInclude )

            # Compare two members lists.
            foreach ($memberToInclude in $MembersToInclude)
            {
                if ($groupMembers -notcontains $memberToInclude)
                {
                    Write-Verbose -Message ($LocalizedData.MemberToIncludeMismatch -f $memberToInclude, 'MembersToInclude', $group.Name)
                    return $false
                }
            }
        }

        if ($PSBoundParameters.ContainsKey('MembersToExclude'))
        {
            $MembersToExclude = @( Remove-DuplicateMembers -Members $MembersToExclude )

            # Compare two members lists.
            foreach ($memberToExclude in $MembersToExclude)
            {
                if ($groupMembers -notcontains $memberToExclude)
                {
                    Write-Verbose -Message ($LocalizedData.MemberToExcludeMismatch -f $memberToExclude, 'MembersToExclude', $group.Name)
                    return $false
                }
            }
        }
    }

    # All properties match. Return $true.
    return $true
}

<#
    .SYNOPSIS
        Removes duplicates members from a list of members.

    .PARAMETER Members
        The list of members to remove duplicates from.
#>
function Remove-DuplicateMembers
{
    [OutputType([String[]])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $Members
    )

    Set-StrictMode -Version 'Latest'

    $membersWithoutDuplicates = @()

    foreach ($member in $Members)
    {
        if ($membersWithoutDuplicates -notcontains $member)
        {
            $membersWithoutDuplicates += $member
        }
    }

    return $membersWithoutDuplicates
}

<#
    .SYNOPSIS
        Retrieves the members of a group on a Nano server.

    .PARAMETER Group
        The LocalGroup Object to retrieve members for.
#>
function Get-MembersOnNanoServer
{
    [OutputType([System.String[]])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [Microsoft.PowerShell.Commands.LocalGroup]
        $Group
    )

    Set-StrictMode -Version 'Latest'

    $localMemberNames = New-Object -TypeName 'System.Collections.ArrayList'

    # Get the group members.
    $groupMembers = Get-LocalGroupMember -Group $Group

    foreach ($groupMember in $groupMembers)
    {
        if ($groupMember.PrincipalSource -ieq 'Local')
        {
            $localMemberName = $groupMember.Name.Substring($groupMember.Name.IndexOf('\') + 1)
            $localMemberNames.Add($localMemberName) | Out-Null
        }
        else
        {
            Write-Verbose -Message "$($groupMember.Name) is not a local user (PrincipalSource = $($groupMember.PrincipalSource))"
        }
    }

    return $localMemberNames.ToArray()
}

<#
    .SYNOPSIS
        Retrieves the members of the given a group on a full server.

    .PARAMETER Group
        The GroupPrincipal Object to retrieve members for.

    .PARAMETER PrincipalContexts
        A hashtable cache of PrincipalContext instances for each scope.
        This is used to cache PrincipalContext instances for cases where it is used multiple times.

    .PARAMETER Disposables
        The ArrayList of disposable objects to which to add any objects that need to be disposed.

    .PARAMETER Credential
        The network credential to use when explicit credentials are needed for the target domain.
#>
function Get-MembersOnFullSKU
{
    [OutputType([System.String[]])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.DirectoryServices.AccountManagement.GroupPrincipal]
        $Group,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [Hashtable]
        [AllowEmptyCollection()]
        $PrincipalContexts,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Collections.ArrayList]
        [AllowEmptyCollection()]
        $Disposables,

        [System.Net.NetworkCredential]
        $Credential
    )

    Set-StrictMode -Version 'Latest'

    $members = New-Object -TypeName 'System.Collections.ArrayList'

    $membersAsPrincipals = @( Get-MembersAsPrincipals -Group $Group -PrincipalContexts $PrincipalContexts -Disposables  $Disposables -Credential $Credential )

    foreach ($membersAsPrincipal in $membersAsPrincipals)
    {
        if ($membersAsPrincipal.ContextType -eq [System.DirectoryServices.AccountManagement.ContextType]::Domain)
        {
            # Select only the first part of the full domain name.
            $domainName = $membersAsPrincipal.Context.Name

            $domainNameDotIndex = $domainName.IndexOf('.')
            if ($domainNameDotIndex -ne -1)
            {
                $domainName = $domainName.Substring(0, $domainNameDotIndex)
            }

            if ($membersAsPrincipal.StructuralObjectClass -ieq 'computer')
            {
                $members.Add($domainName + '\' + $membersAsPrincipal.Name) | Out-Null
            }
            else
            {
                $members.Add($domainName + '\' + $membersAsPrincipal.SamAccountName) | Out-Null
            }
        }
        else
        {
            $members.Add($membersAsPrincipal.Name) | Out-Null
        }
    }

    return $members.ToArray()
}

<#
    .SYNOPSIS
        Retrieves the members of a group as Principal instances.

    .PARAMETER Group
        The group to retrieve members for.

    .PARAMETER PrincipalContexts
        A hashtable cache of PrincipalContext instances for each scope.
        This is used to cache PrincipalContext instances for cases where it is used multiple times.

    .PARAMETER Disposables
        The ArrayList of disposable objects to which to add any objects that need to be disposed.

    .PARAMETER Credential
        The network credential to use when explicit credentials are needed for the target domain.
#>
function Get-MembersAsPrincipals
{
    [OutputType([System.DirectoryServices.AccountManagement.Principal[]])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.DirectoryServices.AccountManagement.GroupPrincipal]
        $Group,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [Hashtable]
        [AllowEmptyCollection()]
        $PrincipalContexts,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Collections.ArrayList]
        [AllowEmptyCollection()]
        $Disposables,

        [System.Net.NetworkCredential]
        $Credential
    )

    Set-StrictMode -Version 'latest'

    $principals = New-Object -TypeName 'System.Collections.ArrayList'

    <#
        This logic enumerates the group members using the underlying DirectoryEntry API. This is
        needed because enumerating the group members as principal instances causes a resolve to
        occur. Since there is no facility for passing credentials to perform the resolution, any
        members that cannot be resolved using the current user will fail (such as when this
        resource runs as SYSTEM). Dropping down to the underyling DirectoryEntry API allows us to
        access the account's SID which can then be used to resolve the associated principal using
        explicit credentials.
    #>
    $groupDirectoryEntry = $group.GetUnderlyingObject()

    $groupDirectoryMembers = $groupDirectoryEntry.Invoke('Members')
    foreach ($groupDirectoryMember in $groupDirectoryMembers)
    {
        # Extract the ObjectSid from the underlying DirectoryEntry
        $memberDirectoryEntry = New-Object -TypeName 'System.DirectoryServices.DirectoryEntry' -ArgumentList @( $groupDirectoryMember )
        $disposables.Add($memberDirectoryEntry) | Out-Null

        $memberDirectoryEntryPathParts = $memberDirectoryEntry.Path.Split('/')

        if ($memberDirectoryEntryPathParts.Count -eq 4)
        {
            # Parsing WinNT://domainname/accountname or WinNT://machinename/accountname
            $scope = $memberDirectoryEntryPathParts[2]
            $accountName = $memberDirectoryEntryPathParts[3]
        }
        elseif ($memberDirectoryEntryPathParts.Count -eq 5)
        {
            # Parsing WinNT://domainname/machinename/accountname
            $scope = $memberDirectoryEntryPathParts[3]
            $accountName = $memberDirectoryEntryPathParts[4]
        }
        else
        {
            <#
                The account is stale either becuase it was deleted or the machine was moved to a
                new domain without removing the domain members from the group. If we consider this
                a fatal error, the group is no longer managable by the DSC resource.  Writing a
                warning allows the operation to complete while leaving the stale member in the
                group.
            #>
            Write-Warning -Message ($LocalizedData.MemberNotValid -f $groupDirectoryEntry.Path)
            continue
        }

        $principalContext = Get-PrincipalContext `
            -PrincipalContexts $PrincipalContexts `
            -Disposables $Disposables `
            -Scope $scope `
            -Credential $Credential

        # If local machine qualified, get the PrincipalContext for the local machine
        if (Test-IsLocalMachine -Scope $scope)
        {
            Write-Verbose -Message ($LocalizedData.ResolvingLocalAccount -f $accountName)
        }
        # The account is domain qualified - credential required to resolve it.
        elseif ($null -ne $Credential -or $null -ne $principalContext)
        {
            Write-Verbose -Message ($LocalizedData.ResolvingDomainAccount -f  $accountName, $scope)
        }
        else
        {
            <#
                The provided name is not scoped to the local machine and no credential was
                provided. This is an unsupported use case. A credential is required to resolve
                off-box.
            #>
            New-InvalidArgumentException `
                -ErrorId 'PrincipalNotFoundNoCredential' `
                -ErrorMessage ($LocalizedData.DomainCredentialsRequired -f $accountName)
        }

        # Create a SID to enable comparison againt the expected member's SID.
        $memberSidBytes = $memberDirectoryEntry.Properties['ObjectSid'].Value
        $memberSid = New-Object -TypeName 'System.Security.Principal.SecurityIdentifier' -ArgumentList @( $memberSidBytes, 0 )

        $principal = Resolve-SidToPrincipal -PrincipalContext $principalContext -Sid $memberSid -Scope $scope
        $disposables.Add($principal) | Out-Null

        $principals.Add($principal) | Out-Null
    }

    return $principals.ToArray()
}

<#
    .SYNOPSIS
        Resolves an array of member names to Principal instances.

    .PARAMETER MemberNames
        The member names to convert to Principal instances.

    .PARAMETER PrincipalContexts
        A hashtable cache of PrincipalContext instances for each scope.
        This is used to cache PrincipalContext instances for cases where it is used multiple times.

    .PARAMETER Disposables
        The ArrayList of disposable objects to which to add any objects that need to be disposed.

    .PARAMETER Credential
        The network credential to use when explicit credentials are needed for the target domain.
#>
function ConvertTo-Principals
{
    [OutputType([System.DirectoryServices.AccountManagement.Principal[]])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [String[]]
        $MemberNames,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [Hashtable]
        [AllowEmptyCollection()]
        $PrincipalContexts,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Collections.ArrayList]
        [AllowEmptyCollection()]
        $Disposables,

        [System.Net.NetworkCredential]
        $Credential
    )

    Set-StrictMode -Version 'Latest'

    $principals = @()
    $uniquePrincipalKeys = @()

    foreach ($memberName in $MemberNames)
    {
        $principal = ConvertTo-Principal `
            -MemberName $memberName `
            -PrincipalContexts $PrincipalContexts `
            -Disposables $Disposables `
            -Credential $Credential

        if ($null -ne $principal)
        {
            # Handle duplicate entries
            if ($principal.ContextType -eq [System.DirectoryServices.AccountManagement.ContextType]::Domain)
            {
                $principalKey = $principal.DistinguishedName
            }
            else
            {
                $principalKey = $principal.SamAccountName
            }

            if ($uniquePrincipalKeys -inotcontains $principalKey)
            {
                $uniquePrincipalKeys += $principalKey
                $principals += $principal
            }
        }
    }

    $uniquePrincipalKeys.Clear()
    return $principals
}

<#
    .SYNOPSIS
        Resolves a member name to a Principal instance.

    .PARAMETER MemberName
        The member name to convert to a Principal instance.

    .PARAMETER PrincipalContexts
        A hashtable cache of PrincipalContext instances for each scope.
        This is used to cache PrincipalContext instances for cases where it is used multiple times.

    .PARAMETER Disposables
        The ArrayList of disposable objects to which to add any objects that need to be disposed.

    .PARAMETER Credential
        The network credential to use when explicit credentials are needed for the target domain.

    .NOTES
        ConvertTo-Principal will fail if a machine name is specified as domainname\machinename. It
        will succeed if the machine name is specified as the SAM name (domainname\machinename$) or
        as the unqualified machine name.

        Split-MemberName splits the scope and account name to avoid this problem.
#>
function ConvertTo-Principal
{
    [OutputType([System.DirectoryServices.AccountManagement.Principal])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [String]
        $MemberName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [Hashtable]
        [AllowEmptyCollection()]
        $PrincipalContexts,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Collections.ArrayList]
        [AllowEmptyCollection()]
        $Disposables,

        [System.Net.NetworkCredential]
        $Credential
    )

    Set-StrictMode -Version 'Latest'

    # The scope of the the object name when in the form of scope\name, UPN, or DN
    $scope, $identityValue = Split-MemberName -MemberName $MemberName

    if (Test-IsLocalMachine -Scope $scope)
    {
        # If local machine qualified, get the PrincipalContext for the local machine
        Write-Verbose -Message ($LocalizedData.ResolvingLocalAccount -f $MemberName)
    }
    elseif ($null -ne $Credential)
    {
        # The account is domain qualified - a credential is provided to resolve it.
        Write-Verbose -Message ($LocalizedData.ResolvingDomainAccount -f  $MemberName, $scope)
    }
    else
    {
        <#
            The provided name is not scoped to the local machine and no credentials were provided.
            If the object is a domain qualified name, we can try to resolve the user with domain
            trust, if setup. When using domain trust, we use the object name to resolve. Object
            name can be in different formats such as a domain qualified name, UPN, or a
            distinguished name for the scope
        #>

        Write-Verbose -Message ($LocalizedData.ResolvingDomainAccountWithTrust -f $MemberName)

        $identityValue = $MemberName
    }

    $principalContext = Get-PrincipalContext `
        -Scope $scope `
        -PrincipalContexts $PrincipalContexts `
        -Disposables $Disposables  `
        -Credential $Credential

    try
    {
        $principal = [System.DirectoryServices.AccountManagement.Principal]::FindByIdentity($principalContext, $identityValue)
    }
    catch [System.Runtime.InteropServices.COMException]
    {
        New-InvalidArgumentException -ArgumentName $MemberName -Message ( $LocalizedData.UnableToResolveAccount -f $MemberName, $_.Exception.Message, $_.Exception.HResult )
    }

    if ($null -eq $principal)
    {
        New-InvalidArgumentException -ArgumentName $MemberName -Message ($LocalizedData.CouldNotFindPrincipal -f $MemberName)
    }

    return $principal
}

<#
    .SYNOPSIS
        Resolves a SID to a principal.

    .PARAMETER Sid
    The security identifier to resolve to a Principal.

    .PARAMETER PrincipalContext
    The PrincipalContext to use to resolve the Principal.

    .PARAMETER Scope
    The scope of the PrincipalContext.
#>
function Resolve-SidToPrincipal
{
    [OutputType([System.DirectoryServices.AccountManagement.Principal])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Security.Principal.SecurityIdentifier]
        $Sid,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.DirectoryServices.AccountManagement.PrincipalContext]
        $PrincipalContext,

        [Parameter(Mandatory = $true)]
        [String]
        $Scope
    )

    Set-StrictMode -Version 'Latest'

    $principal = [System.DirectoryServices.AccountManagement.Principal]::FindByIdentity($PrincipalContext, [System.DirectoryServices.AccountManagement.IdentityType]::Sid, $Sid.Value)

    if ($null -eq $principal)
    {
        if (Test-IsLocalMachine -Scope $Scope)
        {
            $errorId = "PrincipalNotFound_LocalMachine"
        }
        else
        {
            $errorId = "PrincipalNotFound_ProvidedCredential"
        }

        New-InvalidArgumentException -ErrorId $errorId -ErrorMessage ($LocalizedData.CouldNotFindPrincipal -f $Sid.Value)
    }

    return $principal
}

<#
    .SYNOPSIS
        Retrieves a PrincipalContext to use to resolve an object in the given scope.

    .PARAMETER PrincipalContexts
        A hashtable cache of PrincipalContext instances for each scope.
        This is used to cache PrincipalContext instances for cases where it is used multiple times.

    .PARAMETER Disposables
        The ArrayList of disposable objects to which to add any objects that need to be disposed.

    .PARAMETER Scope
        The scope to retrieve the principal context for.

    .PARAMETER Credential
        The network credential to use when explicit credentials are needed for the target domain.

    .NOTES
        When a new PrincipalContext is created, it is added to the Disposables list as well as the PrincipalContexts cache.
#>
function Get-PrincipalContext
{
    [OutputType([System.DirectoryServices.AccountManagement.PrincipalContext])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [Hashtable]
        [AllowEmptyCollection()]
        $PrincipalContexts,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Collections.ArrayList]
        [AllowEmptyCollection()]
        $Disposables,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Scope,

        [System.Net.NetworkCredential]
        $Credential
    )

    $principalContext = $null

    if (Test-IsLocalMachine -Scope $Scope)
    {
        # Check for a cached PrincipalContext for the local machine.
        if ($PrincipalContexts.ContainsKey($env:computerName))
        {
            $principalContext = $PrincipalContexts[$env:computerName]
        }
        else
        {
            # Create a PrincipalContext for the local machine
            $principalContext = New-Object -TypeName 'System.DirectoryServices.AccountManagement.PrincipalContext' -ArgumentList @( [System.DirectoryServices.AccountManagement.ContextType]::Machine )

            # Cache the PrincipalContext for this scope for subsequent calls.
            $PrincipalContexts.Add($env:COMPUTERNAME, $principalContext) | Out-Null
            $Disposables.Add($principalContext) | Out-Null
        }
    }
    elseif ($PrincipalContexts.ContainsKey($Scope))
    {
        $principalContext = $PrincipalContexts[$Scope]
    }
    elseif ($null -ne $Credential)
    {
        # Create a PrincipalContext targeting $Scope using the network credentials that were passed in.
        if ($Credential.Domain)
        {
            $principalContextName = "$($Credential.Domain)\$($Credential.UserName)"
        }
        else
        {
            $principalContextName = $Credential.UserName
        }
        $principalContext = New-Object -TypeName 'System.DirectoryServices.AccountManagement.PrincipalContext' -ArgumentList @( [System.DirectoryServices.AccountManagement.ContextType]::Domain, $Scope, $principalContextName, $Credential.Password )

        # Cache the PrincipalContext for this scope for subsequent calls.
        $PrincipalContexts.Add($scope, $principalContext) | Out-Null
        $Disposables.Add($principalContext) | Out-Null
    }
    else
    {
        # Get a PrincipalContext for the current user in the target domain (even for local System account).
        $principalContext = New-Object -TypeName 'System.DirectoryServices.AccountManagement.PrincipalContext' -ArgumentList @( [System.DirectoryServices.AccountManagement.ContextType]::Domain, $Scope )

        # Cache the PrincipalContext for this scope for subsequent calls.
        $PrincipalContexts.Add($Scope, $principalContext) | Out-Null
        $Disposables.Add($principalContext) | Out-Null
    }

    return $principalContext
}

<#
    .SYNOPSIS
        Adds the given members to the given group if the members are not already in the group.

        Returns true if the members were added and false if all the given members were already
        present.

    .PARAMETER Group
        The group to add the members to.

    .PARAMETER MembersAsPrincipals
        The members to add to the group as principal objects.
#>
function Add-GroupMembers
{
    [OutputType([Boolean])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.DirectoryServices.AccountManagement.GroupPrincipal]
        $Group,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.DirectoryServices.AccountManagement.Principal[]]
        $MembersAsPrincipals
    )

    Set-StrictMode -Version 'Latest'

    $memberAdded = $false

    foreach ($member in $MembersAsPrincipals)
    {
        if (-not $group.Members.Contains($member))
        {
            $group.Members.Add($member)
            $memberAdded = $true
        }
    }

    return $memberAdded
}

<#
    .SYNOPSIS
        Removes the given members from the given group if the members are in the group.

        Returns true if the members were removed and false if none of the given members were in the
        group.

    .PARAMETER Group
        The group to remove the members from.

    .PARAMETER MembersAsPrincipals
        The members to remove from the group as principal objects.
#>
function Remove-GroupMembers
{
    [OutputType([Boolean])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.DirectoryServices.AccountManagement.GroupPrincipal]
        $Group,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.DirectoryServices.AccountManagement.Principal[]]
        $MembersAsPrincipals
    )

    Set-StrictMode -Version 'Latest'

    $memberRemoved = $false

    foreach ($member in $MembersAsPrincipals)
    {
        if ($group.Members.Remove($member))
        {
            $memberRemoved = $true
        }
    }

    return $memberRemoved
}

<#
    .SYNOPSIS
        Determines if a scope represents the current machine.

    .PARAMETER Scope
        The scope to test.
#>
function Test-IsLocalMachine
{
    [OutputType([Boolean])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $Scope
    )

    Set-StrictMode -Version 'latest'

    $localMachineScopes = @( '.', $env:computerName, 'localhost', '127.0.0.1' )

    if ($localMachineScopes -icontains $Scope)
    {
        return $true
    }

    <#
        Determine if we have an ip address that matches an ip address on one of the network
        adapters. This is likely overkill. Consider removing it.
    #>
    if ($Scope.Contains('.'))
    {
        $win32NetworkAdapterConfigurations = @( Get-CimInstance -ClassName 'Win32_NetworkAdapterConfiguration' )
        foreach ($win32NetworkAdapterConfiguration in $win32NetworkAdapterConfigurations)
        {
            if ($null -ne $win32NetworkAdapterConfiguration.IPaddress)
            {
                foreach ($ipAddress in $win32NetworkAdapterConfiguration.IPAddress)
                {
                    if ($ipAddress -eq $Scope)
                    {
                        return $true
                    }
                }
            }
        }
    }

    return $false
}

<#
    .SYNOPSIS
        Splits a member name into the scope and the account name.


    .DESCRIPTION
        The returned $scope is used to determine where to perform the resolution, the local machine
        or a target domain. The returned $accountName is the name of the account to resolve.

        The following details the formats that are handled as well as how the values are
        determined:

        Domain Qualified Names: (domainname\username)

        The value is split on the first '\' character with the left hand side returned as the scope
        and the right hand side returned as the account name.

        UPN: (username@domainname)

        The value is split on the first '@' character with the left hand side returned as the
        account name and the right hand side returned as the scope.

        Distinguished Name:

        The value at the first occurance of 'DC=' is used to extract the unqualified domain name.
        The incoming string is returned, as is, for the account name.

        Unqualified Account Names:

        The incoming string is returned as the account name and the local machine name is returned
        as the scope. Note that values that do not fall into the above categories are interpreted
        as unqualified account names.

    .PARAMETER MemberName
        The full name of the member to split.

    .NOTES
        ConvertTo-Principal will fail if a machine name is specified as domainname\machinename. It
        will succeed if the machine name is specified as the SAM name (domainname\machinename$) or
        as the unqualified machine name.

        Split-MemberName splits the scope and account name to avoid this problem.
#>
function Split-MemberName
{
    [OutputType([String], [String])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $MemberName
    )

    Set-StrictMode -Version 'latest'

    # Assume no scope is defined or $FullName is a DistinguishedName
    $scope = $env:computerName
    $accountName = $MemberName

    # Parse domain or machine qualified account name
    $separatorIndex = $MemberName.IndexOf('\')
    if ($separatorIndex -ne -1)
    {
        $scope = $MemberName.Substring(0, $separatorIndex)

        if (Test-IsLocalMachine -Scope $scope)
        {
            $scope = $env:computerName
        }

        $accountName = $MemberName.Substring($separatorIndex + 1)

        return $scope, $accountName
    }

    # Parse UPN for the scope
    $separatorIndex = $MemberName.IndexOf('@')
    if ($separatorIndex -ne -1)
    {
        $scope = $MemberName.Substring($separatorIndex + 1)
        $accountName = $MemberName.Substring(0, $separatorIndex)

        return $scope, $accountName
    }

    # Parse distinguished name for the scope
    $distinguishedNamePrefix = 'DC='

    $separatorIndex = $MemberName.IndexOf($distinguishedNamePrefix, [System.StringComparison]::OrdinalIgnoreCase)
    if ($separatorIndex -ne -1)
    {
        <#
            For distinguished name formats, the DistinguishedName is returned as the account name.
            See the initialization of $accountName above.
        #>

        $startScopeIndex = $separatorIndex + $distinguishedNamePrefix.Length
        $endScopeIndex = $MemberName.IndexOf(',', $startScopeIndex)

        if ($endScopeIndex -gt $startScopeIndex)
        {
            $scopeLength = $endScopeIndex - $separatorScopeIndex - $distinguishedNamePrefix.Length
            $scope = $MemberName.Substring($startScopeIndex, $scopeLength)

            return $scope, $accountName
        }
    }

    return $scope, $accountName
}

<#
    .SYNOPSIS
        Disposes of the contents of an array list containing IDisposable objects.

    .PARAMETER Disosables
        The array list of IDisposable Objects to dispose of.
#>
function Remove-Disposables
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Collections.ArrayList]
        [AllowEmptyCollection()]
        $Disposables
    )

    Set-StrictMode -Version 'latest'

    foreach ($disposable in $Disposables)
    {
        if ($disposable -is [System.IDisposable])
        {
            $disposable.Dispose()
        }
    }
}

<#
    .SYNOPSIS
        Retrieves a local Windows group.

    .PARAMETER GroupName
        The name of the group to retrieve.

    .PARAMETER Disposables
        The ArrayList of disposable objects to which to add any objects that need to be disposed.

    .PARAMETER PrincipalContexts
        A hashtable cache of PrincipalContext instances for each scope.
        This is used to cache PrincipalContext instances for cases where it is used multiple times.

    .NOTES
        The returned value is NOT added to the $disposables list because the caller may need to
        call $group.Delete() which also disposes it.
#>
function Get-Group
{
    [OutputType([System.DirectoryServices.AccountManagement.GroupPrincipal])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $GroupName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Collections.ArrayList]
        [AllowEmptyCollection()]
        $Disposables,

        [Parameter(Mandatory = $true)]
        [Hashtable]
        [AllowEmptyCollection()]
        $PrincipalContexts
    )

    $principalContext = Get-PrincipalContext `
        -PrincipalContexts $PrincipalContexts `
        -Disposables $Disposables `
        -Scope $env:computerName

    try
    {
        $group = [System.DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity($principalContext, $GroupName)
    }
    catch
    {
        $group = $null 
    }

    return $group
}

<#
    .SYNOPSIS
        Throws an error if a group name contains invalid characters.

    .PARAMETER GroupName
        The group name to test.
#>
function Assert-GroupNameValid
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]
        $GroupName
    )

    $invalidCharacters = @( '\', '/', '"', '[', ']', ':', '|', '<', '>', '+', '=', ';', ',', '?', '*', '@' )

    if ($GroupName.IndexOfAny($invalidCharacters) -ne -1)
    {
        New-InvalidArgumentException `
            -ArgumentName 'GroupNameHasInvalidCharacter' `
            -Message ($LocalizedData.InvalidGroupName `
                -f $GroupName, [String]::Join(' ', $invalidCharacters))
    }

    $nameContainsOnlyWhitspaceOrDots = $true

    # Check if the name consists of only periods and/or white spaces.
    for ($groupNameIndex = 0; $groupNameIndex -lt $GroupName.Length; $groupNameIndex++)
    {
        if (-not [Char]::IsWhiteSpace($GroupName, $groupNameIndex) -and $GroupName[$groupNameIndex] -ne '.')
        {
            $nameContainsOnlyWhitspaceOrDots = $false
            break
        }
    }

    if ($nameContainsOnlyWhitspaceOrDots)
    {
        New-InvalidArgumentException `
            -ErrorId 'GroupNameHasOnlyWhiteSpacesAndDots' `
            -Message ($LocalizedData.InvalidGroupName `
                -f $GroupName, [String]::Join(' ', $invalidCharacters))
    }
}

Export-ModuleMember -Function *-TargetResource
