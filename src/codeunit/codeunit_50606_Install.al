codeunit 50606 "Opti Demolition Install"
{
    Subtype = Install;

    trigger OnInstallAppPerDatabase()
    begin
        SetPlanningAsDefaultProfile();
        SetUpgradeTagsOnFreshInstall();
    end;

    local procedure SetPlanningAsDefaultProfile()
    var
        AllProfile: Record "All Profile";
        ModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ModuleInfo);
        AllProfile.SetRange("Profile ID", 'OptiPlanning');
        AllProfile.SetRange("App ID", ModuleInfo.Id());
        if not AllProfile.FindFirst() then
            exit;
        if AllProfile."Default Role Center" then
            exit;
        AllProfile."Default Role Center" := true;
        AllProfile.Modify();
    end;

    local procedure SetUpgradeTagsOnFreshInstall()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Opti Demolition Upgrade Tags";
    begin
        if not UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetInitialVersionUpgradeTag()) then
            UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetInitialVersionUpgradeTag());
    end;
}
