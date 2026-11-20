pageextension 50620 "Work-Hour Templates Ext" extends "Work-Hour Templates"
{
    layout
    {
        addafter(Description)
        {
            field("Default Start Time"; Rec."Default Start Time")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the default start time for work hours using this template.';
            }

            field("Default End Time"; Rec."Default End Time")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the default end time for work hours using this template.';
            }

            field("Non Working Minutes"; Rec."Non Working Minutes")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the number of non-working hours in a 24-hour period, calculated automatically based on default start and end times.';
                Editable = true;
                Style = StandardAccent;
                StyleExpr = true;
            }
            field("Working Hours"; Rec."Working Hours")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the number of working hours in a 24-hour period, calculated automatically based on default start and end times.';
                Editable = false;
                Style = Favorable;
                StyleExpr = true;
            }
        }
    }
}
