tableextension 50615 "Resource Ext" extends Resource
{
    fields
    {
        field(50601; "Day Tasks"; Decimal)
        {

            Editable = false;
            fieldclass = FlowField;
            calcformula = sum("Day Tasks"."Quantity" where("No." = field("No."),
              "Task Date" = field("Date Filter")));
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