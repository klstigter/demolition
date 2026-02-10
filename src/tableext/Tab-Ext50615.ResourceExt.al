tableextension 50615 "Resource Ext" extends Resource
{
    fields
    {
        field(50601; "Day Tasks"; Decimal)
        {

            Editable = false;
            FieldClass = FlowField;
            CalcFormula = sum("Day Tasks"."Quantity" where("No." = field("No."),
              "Task Date" = field("Date Filter")));
        }
        field(50602; "Skills"; integer)
        {
            Caption = 'Skills';

            FieldClass = FlowField;
            CalcFormula = Count("Resource Skill" where("No." = field("No."), type = const("Resource Skill Type"::Resource)));
        }
    }
    keys
    {
        // Add changes to keys here
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;
}