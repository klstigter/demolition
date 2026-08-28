pageextension 50626 "Skill Codes Opt." extends "Skill Codes"
{
    layout
    {
        addafter(Description)
        {
            field("Invoice Resource No."; Rec."Invoice Resource No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the resource that should be used when invoicing usage recorded under this skill.';
            }
            field("Bar Color"; Rec."Bar Color")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the color of the bar that is used to represent this skill in the Bar chart.';

                trigger OnAssistEdit()
                var
                    ColorPickerPage: Page "Color Picker Lookup";
                begin
                    ColorPickerPage.SetInitialColor(Rec."Bar Color");
                    if ColorPickerPage.RunModal() = Action::OK then begin
                        Rec."Bar Color" := ColorPickerPage.GetSelectedColor();
                        Rec.Modify(true);
                        CurrPage.Update(false);
                    end;
                end;
            }
            field("Font Color"; Rec."Font Color")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the color of the font that is used to represent this skill in the Bar chart.';

                trigger OnAssistEdit()
                var
                    ColorPickerPage: Page "Color Picker Lookup";
                begin
                    ColorPickerPage.SetInitialColor(Rec."Font Color");
                    if ColorPickerPage.RunModal() = Action::OK then begin
                        Rec."Font Color" := ColorPickerPage.GetSelectedColor();
                        Rec.Modify(true);
                        CurrPage.Update(false);
                    end;
                end;
            }
            field("Border Color"; Rec."Border Color")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the color of the border that is used to represent this skill in the Bar chart.';

                trigger OnAssistEdit()
                var
                    ColorPickerPage: Page "Color Picker Lookup";
                begin
                    ColorPickerPage.SetInitialColor(Rec."Border Color");
                    if ColorPickerPage.RunModal() = Action::OK then begin
                        Rec."Border Color" := ColorPickerPage.GetSelectedColor();
                        Rec.Modify(true);
                        CurrPage.Update(false);
                    end;
                end;
            }

        }
    }
}
