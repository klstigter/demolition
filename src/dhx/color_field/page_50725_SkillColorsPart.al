page 50725 "Opti Skill Colors Part"
{
    PageType = CardPart;
    ApplicationArea = All;
    Caption = 'Skill Colors';
    SourceTable = "Skill Code";

    layout
    {
        area(Content)
        {
            usercontrol(CfBarColor; "OptiDHXColorFieldAddin")
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    ColorFieldReady();
                end;

                trigger OnPickRequested()
                begin
                    PickColor(Rec."Opti Bar Color");
                end;

                trigger OnResetRequested()
                var
                    DefaultColor: Text;
                begin
                    if Rec.Code = '' then
                        exit;
                    ClearColor(Rec."Opti Bar Color");
                    DefaultColor := VisualDefaultSettings.GetSkillBarColor(Rec.Code, GetSkillPaletteIndex());
                    ResetColor(Rec."Opti Bar Color", DefaultColor);
                end;

                trigger OnClearRequested()
                begin
                    if Rec.Code = '' then
                        exit;
                    ClearColor(Rec."Opti Bar Color");
                end;
            }
            usercontrol(CfFontColor; "OptiDHXColorFieldAddin")
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    ColorFieldReady();
                end;

                trigger OnPickRequested()
                begin
                    PickColor(Rec."Opti Font Color");
                end;

                trigger OnResetRequested()
                var
                    DefaultColor: Text;
                begin
                    if Rec.Code = '' then
                        exit;
                    ClearColor(Rec."Opti Font Color");
                    DefaultColor := VisualDefaultSettings.GetSkillFontColor(Rec.Code);
                    ResetColor(Rec."Opti Font Color", DefaultColor);
                end;

                trigger OnClearRequested()
                begin
                    if Rec.Code = '' then
                        exit;
                    ClearColor(Rec."Opti Font Color");
                end;
            }
            usercontrol(CfBorderColor; "OptiDHXColorFieldAddin")
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    ColorFieldReady();
                end;

                trigger OnPickRequested()
                begin
                    PickColor(Rec."Opti Border Color");
                end;

                trigger OnResetRequested()
                var
                    DefaultColor: Text;
                begin
                    if Rec.Code = '' then
                        exit;
                    ClearColor(Rec."Opti Border Color");
                    DefaultColor := VisualDefaultSettings.GetSkillBorderColor(Rec.Code, GetSkillPaletteIndex());
                    ResetColor(Rec."Opti Border Color", DefaultColor);
                end;

                trigger OnClearRequested()
                begin
                    if Rec.Code = '' then
                        exit;
                    ClearColor(Rec."Opti Border Color");
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
        CurrPage.CfBarColor.SetValue('Bar Color', Rec."Opti Bar Color");
        CurrPage.CfFontColor.SetValue('Font Color', Rec."Opti Font Color");
        CurrPage.CfBorderColor.SetValue('Border Color', Rec."Opti Border Color");
    end;

    local procedure PickColor(var ColorValue: Text[50])
    var
        ColorPickerPage: Page "Opti Color Picker Lookup";
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

    local procedure ResetColor(var ColorValue: Text[50]; DefaultValue: Text)
    begin
        ColorValue := CopyStr(DefaultValue, 1, MaxStrLen(ColorValue));
        Rec.Modify(true);
        PushColorFields();
    end;

    local procedure ClearColor(var ColorValue: Text[50])
    begin
        ColorValue := '';
        Rec.Modify(true);
        PushColorFields();
    end;

    /// <summary>
    /// Same "0-based, ascending Code order" PaletteIndex convention every other caller of
    /// VisualDefaultSettings.GetSkillBarColor/GetSkillBorderColor uses (see e.g. codeunit 50604's
    /// ReqAssign_BuildSkillColorsJson, codeunit 50695's BuildSkillsJson: unfiltered SkillCodeRec
    /// FindSet(), PaletteIndex incrementing from 0 in Code order). Reproduced here as a plain count
    /// of Skill Codes with a lower Code, since this page only has the single current record, not a
    /// loop to increment a counter through.
    /// </summary>
    local procedure GetSkillPaletteIndex(): Integer
    var
        SkillCodeRec: Record "Skill Code";
    begin
        SkillCodeRec.SetFilter(Code, '<%1', Rec.Code);
        exit(SkillCodeRec.Count());
    end;

    var
        ColorFieldsReadyCount: Integer;
        VisualDefaultSettings: Codeunit "Opti Visual Default Settings";
}
