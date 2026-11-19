codeunit 50740 "Opti Demolition Upgrade Tags"
{
    Access = Internal;

    procedure GetInitialVersionUpgradeTag(): Code[250]
    begin
        exit('OPTI-DAILYOPT-INITIAL-20261119');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerDatabaseUpgradeTags', '', false, false)]
    local procedure RegisterPerDatabaseTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    begin
        if not PerDatabaseUpgradeTags.Contains(GetInitialVersionUpgradeTag()) then
            PerDatabaseUpgradeTags.Add(GetInitialVersionUpgradeTag());
    end;
}
