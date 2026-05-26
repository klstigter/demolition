page 50673 "CapacityApi Opt"
{
    PageType = API;
    Caption = 'Capacity API Optimization';
    APIPublisher = 'BC365Optimizer';
    APIGroup = 'Planning';
    APIVersion = 'v1.0';
    EntityName = 'Capacity';
    EntitySetName = 'Capacities';
    SourceTable = "Res. Capacity Entry";
    SourceTableTemporary = true;
    DelayedInsert = true;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(maxSystemId; Rec.SystemId)
                {
                    Caption = 'System Id';
                }
                field(maxEntryNo; Rec."Entry No.")
                {
                    Caption = 'Entry No.';
                }
                field(date; Rec.Date)
                {
                    Caption = 'Date';
                }
                field(resourceNo; Rec."Resource No.")
                {
                    Caption = 'Resource No.';
                }
                field(duplicateId; Rec."Duplicate Id")
                {
                    Caption = 'Duplicate Id';
                }
                field(capacity; Rec.Capacity)
                {
                    Caption = 'Capacity';
                }
                field(maxSystemCreatedAt; Rec.SystemCreatedAt)
                {
                    Caption = 'Created At';
                }
                field(maxSystemModifiedAt; Rec.SystemModifiedAt)
                {
                    Caption = 'Modified At';
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        Capacity: Record "Res. Capacity Entry";
        CapacityPerDayPerResource: Query "Capacity Per Day Per Resource";
    begin
        if Rec.GetFilter(Date) <> '' then
            CapacityPerDayPerResource.SetFilter(Date_Filter, Rec.GetFilter(Date));
        if Rec.GetFilter("Resource No.") <> '' then
            CapacityPerDayPerResource.SetFilter(Resource_No__Filter, Rec.GetFilter("Resource No."));
        CapacityPerDayPerResource.Open();
        while CapacityPerDayPerResource.Read() do begin
            Capacity.Get(CapacityPerDayPerResource.Entry_No);
            Rec.SystemId := Capacity.SystemId;
            Rec.SystemCreatedAt := Capacity.SystemCreatedAt;
            Rec.SystemModifiedAt := Capacity.SystemModifiedAt;
            Rec."Entry No." := CapacityPerDayPerResource.Entry_No;
            Rec.Date := CapacityPerDayPerResource.Date;
            Rec."Resource No." := CapacityPerDayPerResource.Resource_No_;
            Rec."Duplicate Id" := CapacityPerDayPerResource.Duplicate_Id;
            Rec.Capacity := CapacityPerDayPerResource.Capacity;
            Rec.Insert();
        end;
        CapacityPerDayPerResource.Close();
    end;


}