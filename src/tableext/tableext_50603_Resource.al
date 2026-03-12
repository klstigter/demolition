tableextension 50603 "Resource Opt" extends Resource
{
    fields
    {
        // Add changes to table fields here
        field(50600; "Pool Resource No."; Code[20])
        {
            DataClassification = ToBeClassified;
            tablerelation = Resource;
        }
        field(50610; "Day Task"; Decimal)
        {
            CalcFormula = sum("Day Tasks"."Assigned Hours" where("No." = field("No."),
                                                                    "Task Date" = field("Date Filter")));
            Caption = 'Capacity';
            DecimalPlaces = 0 : 5;
            FieldClass = FlowField;
            Editable = false;
        }
    }

    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        addlast(DropDown; "Resource Group No.")
        {
        }
    }

    var

}