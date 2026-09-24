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

                trigger OnResetRequested()
                var
                    DefaultColor: Text;
                begin
                    if Rec.Code = '' then
                        exit;
                    ClearColor(Rec."Bar Color");
                    DefaultColor := VisualDefaultSettings.GetSkillBarColor(Rec.Code, GetSkillPaletteIndex());
                    ResetColor(Rec."Bar Color", DefaultColor);
                end;

                trigger OnClearRequested()
                begin
                    if Rec.Code = '' then
                        exit;
                    ClearColor(Rec."Bar Color");
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

                trigger OnResetRequested()
                var
                    DefaultColor: Text;
                begin
                    if Rec.Code = '' then
                        exit;
                    ClearColor(Rec."Font Color");
                    DefaultColor := VisualDefaultSettings.GetSkillFontColor(Rec.Code);
                    ResetColor(Rec."Font Color", DefaultColor);
                end;

                trigger OnClearRequested()
                begin
                    if Rec.Code = '' then
                        exit;
                    ClearColor(Rec."Font Color");
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

                trigger OnResetRequested()
                var
                    DefaultColor: Text;
                begin
                    if Rec.Code = '' then
                        exit;
                    ClearColor(Rec."Border Color");
                    DefaultColor := VisualDefaultSettings.GetSkillBorderColor(Rec.Code, GetSkillPaletteIndex());
                    ResetColor(Rec."Border Color", DefaultColor);
                end;

                trigger OnClearRequested()
                begin
                    if Rec.Code = '' then
                        exit;
                    ClearColor(Rec."Border Color");
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
        VisualDefaultSettings: Codeunit "Visual Default Settings";
}
