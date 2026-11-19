codeunit 50741 "Opti Demolition Upgrade"
{
    Subtype = Upgrade;

    trigger OnUpgradePerDatabase()
    begin
        SetInitialVersionTag();
    end;

    local procedure SetInitialVersionTag()
    var
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagDefinitions: Codeunit "Opti Demolition Upgrade Tags";
    begin
        if UpgradeTag.HasUpgradeTag(UpgradeTagDefinitions.GetInitialVersionUpgradeTag()) then
            exit;
        // Add data upgrade logic for versions prior to the tag here.
        UpgradeTag.SetUpgradeTag(UpgradeTagDefinitions.GetInitialVersionUpgradeTag());
    end;
}
