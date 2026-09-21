page 50725 "Skill Colors Part"
{
    PageType = CardPart;
    ApplicationArea = All;
    Caption = 'Skill Colors';
    SourceTable = "Skill Code";

    layout
    {
        area(Content)
        {
            usercontrol(CfBarColor; DHXColorFieldAddin)
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    ColorFieldReady();
                end;

                trigger OnPickRequested()
                begin
                    PickColor(Rec."Bar Color");
                end;
            }
            usercontrol(CfFontColor; DHXColorFieldAddin)
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    ColorFieldReady();
                end;

                trigger OnPickRequested()
                begin
                    PickColor(Rec."Font Color");
                end;
            }
            usercontrol(CfBorderColor; DHXColorFieldAddin)
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    ColorFieldReady();
                end;

                trigger OnPickRequested()
                begin
                    PickColor(Rec."Border Color");
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        if ColorFieldsReadyCount >= 3 then
            PushColorFields();
    end;

    local procedure ColorFieldReady()
    begin
        ColorFieldsReadyCount += 1;
        if ColorFieldsReadyCount = 3 then
            PushColorFields();
    end;

    local procedure PushColorFields()
    begin
        CurrPage.CfBarColor.SetValue('Bar Color', Rec."Bar Color");
        CurrPage.CfFontColor.SetValue('Font Color', Rec."Font Color");
        CurrPage.CfBorderColor.SetValue('Border Color', Rec."Border Color");
    end;

    local procedure PickColor(var ColorValue: Text[50])
    var
        ColorPickerPage: Page "Color Picker Lookup";
    begin
        if Rec.Code = '' then
            exit;
        ColorPickerPage.SetInitialColor(ColorValue);
        if ColorPickerPage.RunModal() = Action::OK then begin
            ColorValue := CopyStr(ColorPickerPage.GetSelectedColor(), 1, MaxStrLen(ColorValue));
            Rec.Modify(true);
            PushColorFields();
        end;
    end;

    var
        ColorFieldsReadyCount: Integer;
}
