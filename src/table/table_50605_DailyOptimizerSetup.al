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
        field(60; "Envelope Color"; Text[20])
        {
            Caption = 'Envelope Color';
            DataClassification = CustomerContent;
        }
        field(61; "Envelope Border Color"; Text[20])
        {
            Caption = 'Envelope Border Color';
            DataClassification = CustomerContent;
        }
        field(62; "Assigned Color"; Text[20])
        {
            Caption = 'Assigned Color';
            DataClassification = CustomerContent;
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
        field(65; "Unassigned Capacity Color"; Text[20])
        {
            Caption = 'Unassigned Capacity Color';
            DataClassification = CustomerContent;
        }
        field(66; "External Border Color"; Text[20])
        {
            Caption = 'External Border Color';
            DataClassification = CustomerContent;
        }
        field(67; "Capacity Border Color"; Text[20])
        {
            Caption = 'Capacity Border Color';
            DataClassification = CustomerContent;
        }
        field(68; "Bar Font Color"; Text[20])
        {
            Caption = 'Bar Font Color';
            DataClassification = CustomerContent;
        }
        field(69; "Weekend Color"; Text[20])
        {
            Caption = 'Weekend Color';
            DataClassification = CustomerContent;
        }
        field(70; "Holiday Color"; Text[20])
        {
            Caption = 'Holiday Color';
            DataClassification = CustomerContent;
        }

        // Gantt task bar colors: applicable to Gantt chart only
        // GTB = Gantt Task Bar
        field(79; "GTB Color (non posting)"; Text[20])
        {
            Caption = 'Gantt Task Bar Color (Non-Posting)';
            DataClassification = CustomerContent;
        }
        field(80; "GTB Color"; Text[20])
        {
            Caption = 'Gantt Task Bar Color';
            DataClassification = CustomerContent;
        }
        field(81; "GTB Border Color"; Text[20])
        {
            Caption = 'Gantt Task Bar Border Color';
            DataClassification = CustomerContent;
        }
        field(82; "GTB Progress Color"; Text[20])
        {
            Caption = 'Gantt Task Bar Progress Color';
            DataClassification = CustomerContent;
        }
        field(83; "GTB Font Color"; Text[20])
        {
            Caption = 'Gantt Task Bar Font Color';
            DataClassification = CustomerContent;
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

}