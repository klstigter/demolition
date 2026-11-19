pageextension 50626 "Opti Skill Codes" extends "Skill Codes"
{
    layout
    {
        addafter(Description)
        {
            field("Opti Invoice Resource No."; Rec."Opti Invoice Resource No.")
            {
                Caption = 'Invoice Resource No.';
                ApplicationArea = All;
                ToolTip = 'Specifies the resource that should be used when invoicing usage recorded under this skill.';
            }
            field("Opti Bar Color"; Rec."Opti Bar Color")
            {
                Caption = 'Bar Color';
                ApplicationArea = All;
                ToolTip = 'Specifies the color of the bar that is used to represent this skill in the Bar chart.';

                trigger OnAssistEdit()
                var
                    ColorPickerPage: Page "Opti Color Picker Lookup";
                begin
                    ColorPickerPage.SetInitialColor(Rec."Opti Bar Color");
                    if ColorPickerPage.RunModal() = Action::OK then begin
                        Rec."Opti Bar Color" := ColorPickerPage.GetSelectedColor();
                        Rec.Modify(true);
                        CurrPage.Update(false);
                    end;
                end;
            }
            field("Opti Font Color"; Rec."Opti Font Color")
            {
                Caption = 'Font Color';
                ApplicationArea = All;
                ToolTip = 'Specifies the color of the font that is used to represent this skill in the Bar chart.';

                trigger OnAssistEdit()
                var
                    ColorPickerPage: Page "Opti Color Picker Lookup";
                begin
                    ColorPickerPage.SetInitialColor(Rec."Opti Font Color");
                    if ColorPickerPage.RunModal() = Action::OK then begin
                        Rec."Opti Font Color" := ColorPickerPage.GetSelectedColor();
                        Rec.Modify(true);
                        CurrPage.Update(false);
                    end;
                end;
            }
            field("Opti Border Color"; Rec."Opti Border Color")
            {
                Caption = 'Border Color';
                ApplicationArea = All;
                ToolTip = 'Specifies the color of the border that is used to represent this skill in the Bar chart.';

                trigger OnAssistEdit()
                var
                    ColorPickerPage: Page "Opti Color Picker Lookup";
                begin
                    ColorPickerPage.SetInitialColor(Rec."Opti Border Color");
                    if ColorPickerPage.RunModal() = Action::OK then begin
                        Rec."Opti Border Color" := ColorPickerPage.GetSelectedColor();
                        Rec.Modify(true);
                        CurrPage.Update(false);
                    end;
                end;
            }

        }
        addfirst(FactBoxes)
        {
            part("Opti SkillColorsPart"; "Opti Skill Colors Part")
            {
                ApplicationArea = All;
                Caption = 'Skill Colors';
                SubPageLink = Code = field(Code);
            }
        }
    }
}
