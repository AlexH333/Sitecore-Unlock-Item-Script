$rootItem = Get-Item -Path "master:/sitecore/media library"
    $user = "username should be selected"
    
    $dialogParams = @{
        Title = "Unlock media items"
        Description = "All media items locked by the selected user will be unlocked."
        OkButtonName = "Proceed" 
        CancelButtonName = "Cancel" 
        ShowHints = $true
        Width = 550
        Height = 400
        Icon = [regex]::Replace($PSScript.Appearance.Icon, "Office", "OfficeWhite", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        Parameters = @(
            @{ 
                Name = "rootItem" 
                Title = "Choose the root folder"
                Tooltip = "Only items from this root will be unlocked."
                Editor = "droptree"
                Source = "/sitecore/media library"
            },
            @{ 
                Name = "user" 
                Title = "Choose a username"
                Editor = "user"
                Tooltip = "Please select Username."
                Mandatory = $true
            }
        )
        Validator = {
            # Ensure the user selected
            if ($variables.user.Value -eq "username should be selected") {
                $variables.user.Error = "User not selected."
            }
        }    
    }
    
    $result = Read-Variable @dialogParams
    
    if($result -eq "cancel") {
        Close-Window
        Exit
    }
    
    $result2 = Show-Confirm -Title "Are you sure you want to unlock items for user $user ?"
    
    if($result2 -eq "no") {
        Close-Window
        Exit
    }
        
    $script:counter = 0
    $script:unlockedCounter = 0
    
    $owner = $user.Replace("\","\\")
    
    function Unlock-Item-ChieldItems-AllVersions {
        param(
            [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
            [Sitecore.Data.Items.Item]$item
        )
    
        $script:counter++
        if ($script:counter % 10000 -eq 0) {
            Write-Host "$script:counter items reviewed"
        }
    
        if ($item["__Lock"] -match $owner) {
            Write-Host "Unlocking" $item.Paths.ContentPath ":" $item.ID "for Language" $version.Language
            Unlock-Item $item #| Out-Null
            $script:unlockedCounter++
        }
    
        foreach ($childItem in $item.Children) {
            foreach ($version in $childItem.Versions.GetVersions($true)){
                Unlock-Item-ChieldItems-AllVersions -Item $version   
            }
        } 
    }
    
    Unlock-Item-ChieldItems-AllVersions -Item $rootItem
    
    Write-Host "Unlocked $script:unlockedCounter total items"
    Write-Host "Reviewed $script:counter total items"
    
    Show-Alert -Title "$script:unlockedCounter items unlocked for a user $user"
    Close-Window