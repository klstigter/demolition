codeunit 50606 "Demolition Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        SetPlanningAsDefaultProfile();
    end;

    local procedure SetPlanningAsDefaultProfile()
    var
        AllProfile: Record "All Profile";
        ModuleInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ModuleInfo);
        AllProfile.SetRange("Profile ID", 'PLANNING');
        AllProfile.SetRange("App ID", ModuleInfo.Id());
        if not AllProfile.FindFirst() then
            exit;
        if AllProfile."Default Role Center" then
            exit;
        AllProfile."Default Role Center" := true;
        AllProfile.Modify();
    end;
}
