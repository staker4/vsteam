function Get-VSTeamRelease {
   [CmdletBinding(DefaultParameterSetName = 'List',
    HelpUri='https://methodsandpractices.github.io/vsteam-docs/docs/modules/vsteam/commands/Get-VSTeamRelease')]
   param(
      [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'ByIdRaw')]
      [Parameter(Position = 0, Mandatory = $true, ParameterSetName = 'ByID', ValueFromPipelineByPropertyName = $true)]
      [Alias('ReleaseID')]
      [int[]] $id,

      [Parameter(ParameterSetName = 'List')]
      [string] $searchText,

      [Parameter(ParameterSetName = 'List')]
      [ValidateSet('Draft', 'Active', 'Abandoned')]
      [string] $statusFilter,

      [ValidateSet('environments', 'artifacts', 'approvals', 'none')]
      [string] $expand,

      [Parameter(ParameterSetName = 'List')]
      [int] $definitionId,

      [Parameter(ParameterSetName = 'List')]
      [int] $top,

      [Parameter(ParameterSetName = 'List')]
      [string] $createdBy,

      [Parameter(ParameterSetName = 'List')]
      [DateTime] $minCreatedTime,

      [Parameter(ParameterSetName = 'List')]
      [DateTime] $maxCreatedTime,

      [Parameter(ParameterSetName = 'List')]
      [ValidateSet('ascending', 'descending')]
      [string] $queryOrder,

      [Parameter(ParameterSetName = 'List')]
      [string] $continuationToken,

      [switch] $JSON,

      [Parameter(Mandatory = $true, ParameterSetName = 'ByIdRaw')]
      [switch] $raw,

      [Parameter(Position = 1, ValueFromPipelineByPropertyName = $true)]
      [vsteam_lib.ProjectValidateAttribute($false)]
      [ArgumentCompleter([vsteam_lib.ProjectCompleter])]
      [string] $ProjectName
   )

   process {
      $commonArgs = @{
         subDomain = 'vsrm'
         area      = 'release'
         resource  = 'releases'
         version   = $(_getApiVersion Release)
      }

      if ($id) {
         foreach ($item in $id) {
            $resp = _callAPI @commonArgs -ProjectName $ProjectName -id $item

            if ($JSON.IsPresent) {
               $resp | ConvertTo-Json -Depth 99
            }
            else {
               if (-not $raw.IsPresent) {
                  Write-Output $([vsteam_lib.Release]::new($resp, $ProjectName))
               }
               else {
                  Write-Output $resp
               }
            }
         }
      }
      else {
         if ($ProjectName) {
            $listurl = _buildRequestURI @commonArgs -ProjectName $ProjectName
         }
         else {
            $listurl = _buildRequestURI @commonArgs
         }

         $queryString = @{
            '$top'              = $top
            '$expand'           = $expand
            'createdBy'         = $createdBy
            'queryOrder'        = $queryOrder
            'searchText'        = $searchText
            'statusFilter'      = $statusFilter
            'definitionId'      = $definitionId
            'minCreatedTime'    = $minCreatedTime
            'maxCreatedTime'    = $maxCreatedTime
            'continuationToken' = $continuationToken
         }

         # Call the REST API
         $resp = _callAPI -url $listurl -QueryString $queryString

         if ($JSON.IsPresent) {
            $resp | ConvertTo-Json -Depth 99
         }
         else {
            $objs = @()

            foreach ($item in $resp.value) {
               $objs += [vsteam_lib.Release]::new($item, $ProjectName)
            }

            Write-Output $objs
         }
      }
   }
}
