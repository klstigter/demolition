pageextension 50620 "Opti Work-Hour Templates" extends "Work-Hour Templates"
{
    layout
    {
        addafter(Description)
        {
            field("Opti Default Start Time"; Rec."Opti Default Start Time")
            {
                Caption = 'Default Start Time';
                ApplicationArea = All;
                ToolTip = 'Specifies the default start time for work hours using this template.';
            }

            field("Opti Default End Time"; Rec."Opti Default End Time")
            {
                Caption = 'Default End Time';
                ApplicationArea = All;
                ToolTip = 'Specifies the default end time for work hours using this template.';
            }

            field("Opti Non Working Minutes"; Rec."Opti Non Working Minutes")
            {
                Caption = 'Non Working Minutes';
                ApplicationArea = All;
                ToolTip = 'Specifies the number of non-working hours in a 24-hour period, calculated automatically based on default start and end times.';
                Editable = true;
                Style = StandardAccent;
                StyleExpr = true;
            }
            field("Opti Working Hours"; Rec."Opti Working Hours")
            {
                Caption = 'Working Hours';
                ApplicationArea = All;
                ToolTip = 'Specifies the number of working hours in a 24-hour period, calculated automatically based on default start and end times.';
                Editable = false;
                Style = Favorable;
                StyleExpr = true;
            }
        }
    }
}
