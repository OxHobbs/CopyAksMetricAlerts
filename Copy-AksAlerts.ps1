$sourceRgName = "k8s-rg"
$sourceK8s = "ox-k8s"
$sourceSub = (Get-AzContext).Subscription.Id

$destRgName = "k8s-rg"
$destK8s = "ox-k8s-2"
$destSub = $sourceSub

# --------------------------------------------------------------------------

$alertRules = Get-AzMetricAlertRuleV2 -ResourceGroupName $sourceRgName | Where-Object { $_.TargetResourceId.EndsWith($sourceK8s) }

foreach ($alertRule in $alertRules) {
    # New-AzMetricAlertRuleV2Criteria 
    $newTargetResourceId = $alertRule.TargetResourceId.
        Replace($sourceRgName, $destRgName).
        Replace($sourceK8s, $destK8s).
        Replace($sourceSub, $destSub)

    $newAlertName = $alertRule.Name.Replace($sourceK8s, $destK8s)

    $exists = Get-AzMetricAlertRuleV2 -ResourceGroupName $destRgName -ErrorAction SilentlyContinue | 
        Where-Object Name -eq $newAlertName

    if ($exists) {
        Write-Host "$newAlertName already exists, skipping" -ForegroundColor Green
        continue
    }

    Add-AzMetricAlertRulev2 -ResourceGroupName $destRgName `
                            -Name $newAlertName `
                            -WindowSize $alertRule.WindowSize `
                            -Frequency $alertRule.EvaluationFrequency `
                            -Condition $alertRule.Criteria `
                            -Severity $alertRule.Severity `
                            -TargetResourceId $newTargetResourceId `
                            -Description $alertRule.Description `
                            -Verbose
}