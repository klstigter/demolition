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