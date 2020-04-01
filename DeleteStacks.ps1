Get-Module -ListAvailable -Name 'AWSPowerShell.NetCore'

$initials = Read-Host -Prompt 'Input your initials like AP01'
if ($initials) {
	Write-Host "Checking info of your stacks... [$initials] `n"
} else {
	Write-Warning -Message "you skipped input."
}
try {
$CFN_Stacks = Get-CFNStack | Where-Object {$_.StackName -like "*-$initials-*"}

if ($CFN_Stacks.StackName){
    Write-Host ("Deleting following stacks `n "  +$CFN_Stacks.StackName )
    $Decision = Read-Host -Prompt 'Are you sure you want to delete these stacks?[Yes(Y) / No(N)]'
}
else {
    Write-Host ("congrats! you might have already deleted these stacks" ) 
}
}
catch{ ("Check if you have AWSPowerShell.NetCore")}

#excluding important stacks from accidental delete
$ExcludeList = @("SPP-*-VPC","SPP-*-SECGRPS","SPP-*-EIP","SPP-*-SHARED01-*","*PENT01*")
if($Decision -iin "Yes","Y") #double checking
{
 foreach ($Stack in $CFN_Stacks )
 {
    if ( !($Stack.StackName -notcontains $ExcludeList))
    {
    Write-Host ("Deleting Stack:   " + ($Stack.StackName))
    if ($Stack.StackName -like "*-ECRWorker") #findout if stack is ecrworker then delete all images in the repo
         {
            Write-Host ("Deleting following stacks using Repos" +$Stack.StackName)
             $RepoObj = $Stack.Outputs | where {$_.OutputKey -eq "ECRRepo"}
             $Repo = Get-ECRRepository | where {$_.RepositoryName -eq $RepoObj.OutputValue}
             Write-Host ("Deleting following stacks using Repos" +$Stack.StackName)
             Write-Host ("Repo is" +$Repo)
             Write-Host ("Repo object is " +$RepoObj)

             if ($Repo)
             {
                Write-Host ("Deleting following images using " +$Repo.RepositoryName)
                Remove-ECRRepository -RepositoryName $Repo.RepositoryName -IgnoreExistingImages $true -Force
                Remove-Variable -Name Repo
             }
                 Remove-CFNStack -StackName $Stack.StackName -Force


        }
        #  if ($Stack.StackName -like "*-s3")
        #  {
        #      Write-Host ("Emptying s3 " +$Stack.StackName)
        #      Remove-S3Object -BucketName $Stack.StackName -Key $Stack.StackName
        #      Remove-S3Object -BucketName -like "*-initials-aatrix-mapping" Key $Stack.StackName
        #      if (BucketName -like "*-initials-aatrix-mapping")
        #      {
        #         Remove-S3Object -BucketName -like "*-initials-aatrix-mapping" Key $Stack.StackName
        #      }
        #      Write-Host ("Deleting s3 bucket" +$Stack.StackName)
        #      Remove-S3Bucket -BucketName $Stack.StackName
        # }
   #Delete starts now
    Remove-CFNStack -StackName $Stack.StackName -Force
    Wait-CFNStack -StackName $Stack.StackName -Status DELETE_COMPLETE -Timeout 180
     }  
 }
}
