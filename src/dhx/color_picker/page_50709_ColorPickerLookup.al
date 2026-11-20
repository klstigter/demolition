page 50709 "Color Picker Lookup"
{
    PageType = StandardDialog;
    ApplicationArea = All;
    Caption = 'Select Color';

    layout
    {
        area(Content)
        {
            usercontrol(DhxColorPicker; DHXColorPickerAddin)
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    PickerReady := true;
                    PushInitialColor();
                end;

                trigger OnColorChanged(ColorHex: Text)
                begin
                    SelectedColorHex := ColorHex;
                end;
            }
        }
    }

    /// <summary>
    /// Caller invokes this BEFORE RunModal() to seed the picker with the field's current value.
    /// Cached and pushed once ControlReady fires - same "cache + push on ready" pattern as page
    /// 50692's ChartReady/RefreshChart and page 50704's GridReady/PushGridData, since the control
    /// add-in's browser-side widget is not guaranteed to exist yet when this runs.
    /// </summary>
    procedure SetInitialColor(ColorHex: Text)
    begin
        InitialColorHex := ColorHex;
        SelectedColorHex := ColorHex;
        PushInitialColor();
    end;

    /// <summary>
    /// Caller reads this AFTER RunModal() returns. Only meaningful when the dialog closed with
    /// Action::OK (StandardDialog's own OK button returns Action::OK, not Action::LookupOK - see
    /// this app's own page 50657 "Generate Pre DayPlannings", the established StandardDialog
    /// precedent in this codebase, confirmed via its RunModal() = Action::OK caller pattern) - if
    /// the user cancelled, this still holds whatever was last picked/seeded, so callers must gate
    /// on the RunModal() result, not on this value alone.
    /// </summary>
    procedure GetSelectedColor(): Text
    begin
        exit(SelectedColorHex);
    end;

    local procedure PushInitialColor()
    begin
        if not PickerReady then
            exit; // ControlReady hasn't fired in the browser yet - PushInitialColor runs again
                  // from there once it does.
        CurrPage.DhxColorPicker.SetValue(InitialColorHex);
    end;

    var
        PickerReady: Boolean;
        InitialColorHex: Text;
        SelectedColorHex: Text;
}
