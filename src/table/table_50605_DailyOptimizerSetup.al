table 50605 "Daily Optimizer Setup"
{
    DataClassification = ToBeClassified;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(10; "Work hour Template"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Work Hour Template';
            TableRelation = "Work-Hour Template";
        }
        field(15; "Base Calendar"; Code[10])
        {
            DataClassification = CustomerContent;
            Caption = 'Base Calendar';
            TableRelation = "Base Calendar";
        }
        field(20; "Order Intake Nos"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Order Intake Nos';
            TableRelation = "No. Series";
        }
        field(21; "Work Order Nos"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Work Order Nos';
            TableRelation = "No. Series";
        }
        field(30; "Default Skill"; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Default Skill';
            TableRelation = "Skill Code";
        }
        field(40; "TrustedCircle API Base URL"; Text[250])
        {
            Caption = 'API Base URL';
        }
        field(41; "TrustedCircle Bearer Token"; Text[250])
        {
            Caption = 'Bearer Token';
        }
        field(50; "Resource Scheduler - List Type"; Option)
        {
            Caption = 'Resource Scheduler - List Type';
            OptionMembers = "By Resource Group","By Skill";
            OptionCaption = 'By Resource Group,By Skill';
        }
        field(51; "Bar Width (px) - Bar Chart"; Integer)
        {
            Caption = 'Bar Width (px) - Bar Chart';
            DataClassification = ToBeClassified;
            ToolTip = 'Specifies the width, in pixels, of each bar on the Requested Hours vs Capacity bar charts (Daily and Weekly). Leave at 0 to use the chart''s default width.';
        }

        // Bar Colors: applicable to Scheduler Timeline and Bar Chart
        field(59; "Free Capacity-Mandatory Color"; Text[20])
        {
            Caption = 'Free Capacity (Mandatory) Color';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                RestoreColorDefaultOnClear(Rec."Free Capacity-Mandatory Color", xRec."Free Capacity-Mandatory Color", VisualDefaultSettings.GetDefaultCapacityMandatoryColor());
            end;
        }
        field(60; "Envelope Color"; Text[20])
        {
            Caption = 'Envelope Color';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                RestoreColorDefaultOnClear(Rec."Envelope Color", xRec."Envelope Color", VisualDefaultSettings.GetDefaultEnvelopeColor());
            end;
        }
        field(61; "Envelope Border Color"; Text[20])
        {
            Caption = 'Envelope Border Color';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                RestoreColorDefaultOnClear(Rec."Envelope Border Color", xRec."Envelope Border Color", VisualDefaultSettings.GetDefaultEnvelopeBorderColor());
            end;
        }
        field(62; "Assigned Color"; Text[20])
        {
            Caption = 'Assigned Color';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                RestoreColorDefaultOnClear(Rec."Assigned Color", xRec."Assigned Color", VisualDefaultSettings.GetDefaultAssignedColor());
            end;
        }
        field(63; "Assigned High (%)"; Integer)
        {
            Caption = 'Assigned High (%)';
            DataClassification = CustomerContent;
        }
        field(64; "Requested High (%)"; Integer)
        {
            Caption = 'Requested High (%)';
            DataClassification = CustomerContent;
        }
        field(65; "Free Capacity Color"; Text[20])
        {
            Caption = 'Free Capacity Color';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                RestoreColorDefaultOnClear(Rec."Free Capacity Color", xRec."Free Capacity Color", VisualDefaultSettings.GetDefaultCapacityColor());
            end;
        }
        field(66; "External Border Color"; Text[20])
        {
            Caption = 'External Border Color';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                RestoreColorDefaultOnClear(Rec."External Border Color", xRec."External Border Color", VisualDefaultSettings.GetDefaultExternalBorderColor());
            end;
        }
        field(67; "Capacity Border Color"; Text[20])
        {
            Caption = 'Capacity Border Color';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                RestoreColorDefaultOnClear(Rec."Capacity Border Color", xRec."Capacity Border Color", VisualDefaultSettings.GetDefaultCapacityBorderColor());
            end;
        }
        field(68; "Bar Font Color"; Text[20])
        {
            Caption = 'Bar Font Color';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                RestoreColorDefaultOnClear(Rec."Bar Font Color", xRec."Bar Font Color", VisualDefaultSettings.GetDefaultBarFontColor());
            end;
        }
        field(69; "Weekend Color"; Text[20])
        {
            Caption = 'Weekend Color';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                RestoreColorDefaultOnClear(Rec."Weekend Color", xRec."Weekend Color", VisualDefaultSettings.GetDefaultWeekendColor());
            end;
        }
        field(70; "Holiday Color"; Text[20])
        {
            Caption = 'Holiday Color';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                RestoreColorDefaultOnClear(Rec."Holiday Color", xRec."Holiday Color", VisualDefaultSettings.GetDefaultHolidayColor());
            end;
        }

        // Gantt task bar colors: applicable to Gantt chart only
        // GTB = Gantt Task Bar
        field(79; "GTB Color (non posting)"; Text[20])
        {
            Caption = 'Gantt Task Bar Color (Non-Posting)';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                RestoreColorDefaultOnClear(Rec."GTB Color (non posting)", xRec."GTB Color (non posting)", VisualDefaultSettings.GetDefaultGanttTaskBarColorNonPosting());
            end;
        }
        field(80; "GTB Color"; Text[20])
        {
            Caption = 'Gantt Task Bar Color';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                RestoreColorDefaultOnClear(Rec."GTB Color", xRec."GTB Color", VisualDefaultSettings.GetDefaultGanttTaskBarColor());
            end;
        }
        field(81; "GTB Border Color"; Text[20])
        {
            Caption = 'Gantt Task Bar Border Color';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                RestoreColorDefaultOnClear(Rec."GTB Border Color", xRec."GTB Border Color", VisualDefaultSettings.GetDefaultGanttTaskBarBorderColor());
            end;
        }
        field(82; "GTB Progress Color"; Text[20])
        {
            Caption = 'Gantt Task Bar Progress Color';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                RestoreColorDefaultOnClear(Rec."GTB Progress Color", xRec."GTB Progress Color", VisualDefaultSettings.GetDefaultGanttTaskBarProgressColor());
            end;
        }
        field(83; "GTB Font Color"; Text[20])
        {
            Caption = 'Gantt Task Bar Font Color';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                RestoreColorDefaultOnClear(Rec."GTB Font Color", xRec."GTB Font Color", VisualDefaultSettings.GetDefaultGanttTaskBarFontColor());
            end;
        }
        field(84; "GTB Font size (px)"; integer)
        {
            Caption = 'Gantt Task Bar Font Size (px)';
            DataClassification = CustomerContent;
        }
        field(85; "GTB Height (px)"; integer)
        {
            Caption = 'Gantt Task Bar Height (px)';
            DataClassification = CustomerContent;
        }

        // Hover/tooltip popup colors: applicable to every DHX control add-in's hover/tooltip
        // popup (dhtmlx built-in tooltip plugin and custom hover-popup divs alike) - see
        // codeunit 50609 "Visual Default Settings"'s GetTooltipBackgroundColor/GetTooltipFontColor
        // doc comments for the full list of consumers.
        field(86; "Tooltip Background Color"; Text[20])
        {
            Caption = 'Tooltip Background Color';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                RestoreColorDefaultOnClear(Rec."Tooltip Background Color", xRec."Tooltip Background Color", VisualDefaultSettings.GetDefaultTooltipBackgroundColor());
            end;
        }
        field(87; "Tooltip Font Color"; Text[20])
        {
            Caption = 'Tooltip Font Color';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                RestoreColorDefaultOnClear(Rec."Tooltip Font Color", xRec."Tooltip Font Color", VisualDefaultSettings.GetDefaultTooltipFontColor());
            end;
        }
    }

    keys
    {
        key(Key1; "Primary Key")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        // Add changes to field groups here
    }

    var
        myInt: Integer;
        VisualDefaultSettings: Codeunit "Visual Default Settings";

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

    /// <summary>
    /// Shared by every color field's OnValidate trigger above: when the user clears a color field
    /// (new value blank, and it actually changed from a non-blank value - so this doesn't fire on
    /// Insert of a fresh blank record), restores DefaultValue into the field and tells the user via
    /// Message. DefaultValue comes from codeunit 50609 "Visual Default Settings"'s GetDefaultXxx
    /// getters - the same defaults page 50654's "Reset to default" action already restores, so a
    /// cleared field always lands on the same value that action would have set. A couple of those
    /// getters (GTB Progress/Font Color) intentionally return blank - see their own doc comments -
    /// so for those two this is a no-op reassignment that still surfaces the message, confirming the
    /// blank is the field's real default (dynamic/inherited behavior) rather than an accidental clear.
    /// </summary>
    local procedure RestoreColorDefaultOnClear(var NewValue: Text[20]; OldValue: Text[20]; DefaultValue: Text)
    var
        ColorDefaultRestoredMsg: Label 'The color value was cleared, so the system default has been restored automatically.';
    begin
        if (NewValue = '') and (NewValue <> OldValue) then begin
            NewValue := CopyStr(DefaultValue, 1, MaxStrLen(NewValue));
            Message(ColorDefaultRestoredMsg);
        end;
    end;
}